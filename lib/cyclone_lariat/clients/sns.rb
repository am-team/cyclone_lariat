# frozen_string_literal: true

require 'aws-sdk-sns'
require 'cyclone_lariat/fake'
require 'cyclone_lariat/clients/abstract'
require 'cyclone_lariat/resources/topic'
require 'cyclone_lariat/resources/queue'

module CycloneLariat
  module Clients
    class Sns < Abstract
      include LunaPark::Extensions::Injector
      include Generators::Topic

      dependency(:aws_client_class) { Aws::SNS::Client }

      def publish(msg, fifo:, topic: nil, skip_validation: false)
        return Fake.sns_publish_response(msg) if config.fake_publish

        topic = topic ? custom_topic(topic) : topic(msg.type, kind: msg.kind, fifo: fifo)

        raise Errors::GroupIdUndefined.new(resource: topic)       if fifo && msg.group_id.nil?
        raise Errors::GroupDefined.new(resource: topic)           if !fifo && msg.group_id
        raise Errors::DeduplicationIdDefined.new(resource: topic) if !fifo && msg.deduplication_id

        msg.validation.check! unless skip_validation

        params = {
          topic_arn: topic.arn,
          message: msg.to_json,
          message_group_id: msg.group_id,
          message_deduplication_id: msg.deduplication_id
        }.compact

        aws_client.publish(**params)
      end

      def exists?(topic)
        raise ArgumentError, 'Should be Topic' unless topic.is_a? Resources::Topic

        aws_client.get_topic_attributes({ topic_arn: topic.arn }) && true
      rescue Aws::SNS::Errors::NotFound
        false
      end

      def publish_event(type, fifo:, topic: nil, **options)
        options[:version] ||= config.version
        options[:data]    ||= {}
        options[:uuid]    ||= SecureRandom.uuid

        publish event(type, **options), fifo: fifo, topic: topic
      end

      def publish_command(type, fifo:, topic: nil, **options)
        options[:version] ||= config.version
        options[:data]    ||= {}
        options[:uuid]    ||= SecureRandom.uuid

        publish command(type, **options), fifo: fifo, topic: topic
      end

      def create(topic)
        raise ArgumentError, 'Should be Resources::Topic' unless topic.is_a? Resources::Topic
        raise Errors::TopicAlreadyExists.new(expected_topic: topic.name) if exists?(topic)

        aws_client.create_topic(name: topic.name, attributes: topic.attributes, tags: topic.tags)
        topic
      end

      def delete(topic)
        raise ArgumentError, 'Should be Resources::Topic' unless topic.is_a? Resources::Topic
        raise Errors::TopicDoesNotExists.new(expected_topic: topic.name) unless exists?(topic)

        aws_client.delete_topic topic_arn: topic.arn
        topic
      end

      def subscribed?(topic:, endpoint:)
        subscription_arn = find_subscription_arn(topic: topic, endpoint: endpoint)
        !subscription_arn.nil?
      end

      def subscribe(topic:, endpoint:)
        subscription_arn = find_subscription_arn(topic: topic, endpoint: endpoint)
        raise Errors::SubscriptionAlreadyExists.new(topic: topic, endpoint: endpoint) if subscription_arn

        aws_client.subscribe(
          {
            topic_arn: topic.arn,
            protocol: endpoint.protocol,
            endpoint: endpoint.arn
          }
        )
      end

      def unsubscribe(topic:, endpoint:)
        subscription_arn = find_subscription_arn(topic: topic, endpoint: endpoint)
        raise Errors::SubscriptionDoesNotExists.new(topic: topic, endpoint: endpoint) unless subscription_arn

        aws_client.unsubscribe(subscription_arn: subscription_arn)
      end

      def list_all
        topics = []
        resp = aws_client.list_topics

        loop do
          resp[:topics].map do |t|
            topics << Resources::Topic.from_arn(t[:topic_arn])
          end

          break if resp[:next_token].nil?

          resp = aws_client.list_topics(next_token: resp[:next_token])
        end
        topics
      end

      def list_subscriptions
        subscriptions = []
        resp = aws_client.list_subscriptions

        loop do
          resp[:subscriptions].each do |s|
            endpoint =
              case s.protocol
              when 'sqs'
                Resources::Queue.from_arn(s.endpoint)
              when 'sns'
                Resources::Topic.from_arn(s.endpoint)
              else
                next
              end

            subscriptions << {
              topic: Resources::Topic.from_arn(s.topic_arn), endpoint: endpoint,
              arn: s.subscription_arn
            }
          end

          break if resp[:next_token].nil?

          resp = aws_client.list_subscriptions(next_token: resp[:next_token])
        end
        subscriptions
      end

      def topic_subscriptions(topic)
        raise ArgumentError, 'Should be Topic' unless topic.is_a? Resources::Topic

        subscriptions = []

        resp = aws_client.list_subscriptions_by_topic(topic_arn: topic.arn)

        loop do
          next_token = resp[:next_token]
          subscriptions += resp[:subscriptions]

          break if next_token.nil?

          resp = aws_client.list_subscriptions_by_topic(topic_arn: topic.arn, next_token: next_token)
        end
        subscriptions
      end

      def find_subscription_arn(topic:, endpoint:)
        raise ArgumentError, 'Should be Topic' unless topic.is_a? Resources::Topic
        unless [Resources::Topic, Resources::Queue].include? endpoint.class
          raise ArgumentError, 'Endpoint should be Topic or Queue'
        end

        found_subscription = topic_subscriptions(topic).find do |subscription|
          subscription.endpoint == endpoint.arn
        end

        found_subscription&.subscription_arn
      end
    end
  end
end
