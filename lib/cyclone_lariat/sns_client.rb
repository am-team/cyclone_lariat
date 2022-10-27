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

    def exists?(topic)
      aws_client.get_topic_attributes({topic_arn: get_arn(topic)}) && true
    rescue Aws::SNS::Errors::NotFound
      false
    end

    def publish_event(type, data: {}, version: self.version, uuid: SecureRandom.uuid, topic: nil)
      publish event(type, data: data, version: version, uuid: uuid), topic: topic
    end

    def publish_command(type, data: {}, version: self.version, uuid: SecureRandom.uuid, topic: nil)
      publish command(type, data: data, version: version, uuid: uuid), topic: topic
    end

    def create_event_topic!(type:, fifo:)
      create_topic! get_topic('event', type), fifo: fifo
    end

    def create_command_topic!(type:, fifo:)
      create_topic! get_topic('command', type), fifo: fifo
    end

    def create_topic!(topic, fifo:)
      raise Errors::TopicAlreadyExists.new(expected_topic: topic) if exists?(topic)

      attrs = {}
      attrs['FifoTopic'] = true if fifo

      aws_client.create_topic(name: topic, attributes: attrs)
    end

    def delete_event_topic!(type)
      delete_topic! get_topic('event', type)
    end

    def delete_command_topic!(type)
      delete_topic! get_topic('command', type)
    end

    def delete_topic!(topic)
      raise Errors::TopicDoesNotExists.new(expected_topic: topic) unless exists?(topic)

      aws_client.delete_topic topic_arn: get_arn(topic)
    end

    def subscribe(kind:, sns_topic:, sqs_topic:)
      aws_client.subscribe(
        {
          topic_arn: get_arn(sns_topic),
          protocol: 'sqs',
          endpoint: 'que_arn'
        }
      )
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
