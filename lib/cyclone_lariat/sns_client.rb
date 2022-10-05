# frozen_string_literal: true

require 'aws-sdk-sns'
require_relative 'abstract/client'
require_relative 'list_topics_store'

module CycloneLariat
  class SnsClient < Abstract::Client
    include LunaPark::Extensions::Injector

    dependency(:aws_client_class) { Aws::SNS::Client }
    # dependency(:topics_store)     { ListTopicsStore.instance }

    SNS_SUFFIX = :fanout

    def publish(msg, topic: nil)
      topic ||= generate_topic_name(kind: msg.kind, type: msg.type)

      aws_client.publish(
        topic_arn: topic_arn(topic),
        message: msg.to_json
      )
    end

    def publish_event(type, data: {}, version: self.version, uuid: SecureRandom.uuid, topic: nil)
      publish event(type, data: data, version: version, uuid: uuid), topic: topic
    end

    def publish_command(type, data: {}, version: self.version, uuid: SecureRandom.uuid, topic: nil)
      publish command(type, data: data, version: version, uuid: uuid), topic: topic
    end

    def create_event_topic!(type)
      create_topic! generate_topic_name(kind: 'event', type: type)
    end

    def create_command_topic(type)
      create_topic generate_topic_name(kind: 'command', type: type)
    end


    # Unsafify
    def create_topic!(name)
      # raise Errors::TopicAlreadyExists if topics_story.exists?(name)
      puts arn = aws_client.create_topic(name: name)
      # topics_story.cleargit
    end

    def delete_event_topic!(type)
      topic ||= generate_topic_name(kind: 'event', type: type)
      delete_custom_topic! topic
    end

    def delete_command_topic!(type)
      topic ||= generate_topic_name(kind: 'command', type: type)
      delete_custom_topic! topic
    end

    def delete_custom_topic!(topic)
      aws_client.delete_topic topic_arn: topic_arn(topic)
      topics_store.clear_store!
    end

    private

    def generate_topic_name(kind:, type:)
      [instance, kind, SNS_SUFFIX, publisher, type].join('-')
    end

    def topic_arn(topic_name)
      topics_store.add_topics(aws_client)
      topic_arn = topics_store.topic_arn(topic_name)

      if topic_arn.nil?
        raise Errors::TopicNotFound.new(
          expected_topic: topic_name,
          existed_topics: topics_store.list
        )
      end

      topic_arn
    end

    def topics_store
      ListTopicsStore.instance
    end
  end
end
