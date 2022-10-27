# frozen_string_literal: true

require 'aws-sdk-sqs'
require_relative 'abstract/client'

module CycloneLariat
  class SqsClient < Abstract::Client
    include LunaPark::Extensions::Injector

    dependency(:aws_client_class) { Aws::SQS::Client }

    SQS_SUFFIX = :queue

    def exists?(topic_name)
      url(topic_name) && true
    rescue Aws::SQS::Errors::NonExistentQueue
      false
    end

    def publish(msg, dest: nil, topic: nil)
      raise ArgumentError, 'You should define dest or topic' if dest.nil? && topic.nil?

      topic ||= get_topic(kind: msg.kind, type: msg.type, dest: dest)

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

    def create_topic!(topic_name, fifo:, tags: nil)
      raise Errors::TopicAlreadyExists.new(expected_topic: topic_name) if exists?(topic_name)

      attrs = {}
      attrs['FifoQueue'] = true if fifo

      aws_client.create_queue(queue_name: topic_name, attributes: attrs)
    end

    def create_event_topic!(fifo:, type: :all, dest: nil)
      create_topic! get_topic(kind: 'event', type: type, dest: dest), fifo: fifo
    end

    def create_command_topic!(fifo:, type: :all, dest: nil)
      create_topic! get_topic(kind: 'command', type: type, dest: dest), fifo: fifo
    end

    def delete_topic!(topic_name)
      raise Errors::TopicDoesNotExists.new(expected_topic: topic_name) unless exists?(topic_name)

      aws_client.delete_queue queue_url: url(topic_name)
    end

    def delete_event_topic!(type: :all, dest: nil)
      delete_topic! get_topic(kind: :event, type: type, dest: dest)
    end

    def delete_command_topic!(type: :all, dest: nil)
      delete_topic! get_topic(kind: :command, type: type, dest: dest)
    end

    private

    def url(topic_name)
      aws_client.get_queue_url(queue_name: topic_name).queue_url
    end

    def get_topic(kind:, type:, dest:)
      [instance, kind, SQS_SUFFIX, publisher, type, dest].compact.join('-')
    end
  end
end
