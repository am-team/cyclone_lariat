# frozen_string_literal: true

require 'aws-sdk-sns'
require_relative 'abstract/client'

module CycloneLariat
  class SnsClient < Abstract::Client
    include LunaPark::Extensions::Injector

    dependency(:aws_client_class) { Aws::SNS::Client }

    SNS_SUFFIX = :fanout

    def publish(msg, topic: nil)
      topic ||= get_topic(msg.kind, msg.type)
      arn     = get_arn(topic)
      aws_client.publish(topic_arn: arn, message: msg.to_json)
    end

    def publish_event(type, data: {}, version: self.version, uuid: SecureRandom.uuid, topic: nil)
      publish event(type, data: data, version: version, uuid: uuid), topic: topic
    end

    def publish_command(type, data: {}, version: self.version, uuid: SecureRandom.uuid, topic: nil)
      publish command(type, data: data, version: version, uuid: uuid), topic: topic
    end

    private

    def get_arn(topic)
      ['arn', 'aws', 'sns', region, client_id, topic].join ':'
    end

    def get_topic(kind, type)
      [instance, kind, SNS_SUFFIX, publisher, type].join '-'
    end
  end
end
