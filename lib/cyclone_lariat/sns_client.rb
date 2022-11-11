# frozen_string_literal: true

require 'aws-sdk-sns'
require_relative 'abstract/client'
require_relative 'topic'
require_relative 'queue'

module CycloneLariat
  class SnsClient < Abstract::Client
    include LunaPark::Extensions::Injector

    dependency(:aws_client_class) { Aws::SNS::Client }

    def custom_topic(name)
      Topic.from_name(name, account_id: account_id, region: region)
    end

    def topic(type, fifo:, kind: :event)
      Topic.new(
        instance: instance,
        publisher: publisher,
        region: region,
        account_id: account_id,
        kind: kind,
        type: type, fifo: fifo
      )
    end

    def publish(msg, fifo:, topic: nil)
      topic = topic ? custom_topic(topic) : topic(msg.type, kind: msg.kind, fifo: fifo)
      aws_client.publish(topic_arn: topic.arn, message: msg.to_json)
    end

    def exists?(topic)
      raise ArgumentError, 'Should be Topic' unless topic.is_a? Topic

      aws_client.get_topic_attributes({ topic_arn: topic.arn }) && true
    rescue Aws::SNS::Errors::NotFound
      false
    end

    def publish_event(type, fifo:, data: {}, version: self.version, uuid: SecureRandom.uuid, request_id: nil, topic: nil)
      publish event(type, data: data, version: version, uuid: uuid, request_id: request_id), topic: topic, fifo: fifo
    end

    def publish_command(type, fifo:, data: {}, version: self.version, uuid: SecureRandom.uuid, request_id: nil, topic: nil)
      publish command(type, data: data, version: version, uuid: uuid, request_id: request_id), topic: topic, fifo: fifo
    end

    def create(topic)
      raise ArgumentError, 'Should be Topic' unless topic.is_a? Topic
      raise Errors::TopicAlreadyExists.new(expected_topic: topic.name) if exists?(topic)

      aws_client.create_topic(name: topic.name, attributes: topic.attributes, tags: topic.tags)
      topic
    end

    def delete(topic)
      raise ArgumentError, 'Should be Topic' unless topic.is_a? Topic
      raise Errors::TopicDoesNotExists.new(expected_topic: topic.name) unless exists?(topic)

      aws_client.delete_topic topic_arn: topic.arn
      topic
    end

    def subscribe(topic:, endpoint:)
      subscription_arn = find_subscription_arn(topic: topic, endpoint: endpoint)
      raise Errors::SubscriptionAlreadyExists.new(topic: topic, endpoint: endpoint) if subscription_arn

      aws_client.subscribe(
        {
          topic_arn: topic.arn,
          protocol: 'sqs',
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
          topics << Topic.from_arn(t[:topic_arn])
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
          endpoint = s.endpoint.split(':')[2] == 'sqs' ? Queue.from_arn(s.endpoint) : Topic.from_arn(s.endpoint)
          subscriptions << [Topic.from_arn(s.topic_arn), endpoint]
        end

        break if resp[:next_token].nil?

        resp = aws_client.list_subscriptions(next_token: resp[:next_token])
      end
      subscriptions
    end

    def topic_subscriptions(topic)
      raise ArgumentError, 'Should be Topic' unless topic.is_a? Topic

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
      raise ArgumentError, 'Should be Topic' unless topic.is_a? Topic
      raise ArgumentError, 'Endpoint should be Topic or Queue' unless [Topic, Queue].include? endpoint.class

      found_subscription = topic_subscriptions(topic).select do |subscription|
        subscription.endpoint == endpoint.arn
      end.first

      found_subscription ? found_subscription.subscription_arn : nil
    end
  end
end
