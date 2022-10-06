# frozen_string_literal: true

require 'aws-sdk-sqs'
require_relative 'abstract/client'

module CycloneLariat
  class SqsClient < Abstract::Client
    include LunaPark::Extensions::Injector

    dependency(:aws_client_class) { Aws::SQS::Client }

    SQS_SUFFIX = :queue

    def publish(msg, dest: nil, topic: nil)
      raise ArgumentError, 'You should define dest or topic' if dest.nil? && topic.nil?

      topic ||= [instance, msg.kind, SQS_SUFFIX, publisher, msg.type, dest].join('-')

      aws_client.send_message(
        queue_url: url(topic),
        message_body: msg.to_json
      )
    end

    def publish_event(type, dest: nil, data: {}, version: self.version, uuid: SecureRandom.uuid, topic: nil)
      publish event(type, data: data, version: version, uuid: uuid), dest: dest, topic: topic
    end

    def publish_command(type, dest: nil, data: {}, version: self.version, uuid: SecureRandom.uuid, topic: nil)
      publish command(type, data: data, version: version, uuid: uuid), dest: dest, topic: topic
    end

    private

    def url(topic_name)
      aws_client.get_queue_url(queue_name: topic_name).queue_url
    end
  end
end
