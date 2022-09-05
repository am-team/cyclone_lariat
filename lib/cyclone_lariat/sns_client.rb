# frozen_string_literal: true

require 'aws-sdk-sns'
require_relative 'abstract/client'
require_relative 'list_topics_store'

module CycloneLariat
  class SnsClient < Abstract::Client
    include LunaPark::Extensions::Injector

    dependency(:aws_client_class) { Aws::SNS::Client }

    SNS_SUFFIX = :fanout

    def publish(msg, topic: nil)
      topic ||= [instance, msg.kind, SNS_SUFFIX, publisher, msg.type].join('-')

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

    private

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
