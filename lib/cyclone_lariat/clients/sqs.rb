# frozen_string_literal: true

require 'aws-sdk-sqs'
require_relative 'abstract'
require_relative '../resources/queue'

module CycloneLariat
  module Clients
    class Sqs < Abstract
      include LunaPark::Extensions::Injector

      dependency(:aws_client_class) { Aws::SQS::Client }

      def custom_queue(name)
        Resources::Queue.from_name(name, account_id: config.aws_account_id, region: config.aws_region)
      end

      def queue(type = :all, fifo:, dest: nil, publisher: nil, kind: :event)
        publisher ||= config.publisher

        Resources::Queue.new(
          instance: config.instance, publisher: publisher, region: config.aws_region,
          account_id: config.aws_account_id, kind: kind, type: type, fifo: fifo, dest: dest
        )
      end

      def get_url(queue)
        raise ArgumentError, 'Should be queue' unless queue.is_a? Resources::Queue

        aws_client.get_queue_url(queue_name: queue.to_s).queue_url
      end

      def exists?(queue)
        raise ArgumentError, 'Should be queue' unless queue.is_a? Resources::Queue

        get_url(queue) && true
      rescue Aws::SQS::Errors::NonExistentQueue
        false
      end

      def add_policy(queue:, policy:)
        current_policy_json = aws_client.get_queue_attributes({
          queue_url: queue.url,
          attribute_names: ['Policy']
        }).attributes['Policy']


        current_policy = JSON.parse(current_policy_json) if current_policy_json

        if current_policy && current_policy['Statement'].find { |s| s['Sid'] == policy['Sid'] }
          raise Errors::PolicyAlreadyExists.new(sid: policy['Sid'])
        end

        new_policy = current_policy || { 'Statement' => [] }
        new_policy['Statement'] << policy

        aws_client.set_queue_attributes({ queue_url: queue.url, attributes: { 'Policy' => new_policy.to_json } })
      end

      def publish(msg, fifo:, dest: nil, queue: nil)
        queue = queue ? custom_queue(queue) : queue(msg.type, kind: msg.kind, fifo: fifo, dest: dest)
        aws_client.send_message(queue_url: get_url(queue), message_body: msg.to_json)
      end

      def publish_event(type, fifo:, dest: nil, data: {}, version: self.version, uuid: SecureRandom.uuid, request_id: nil, queue: nil)
        publish event(type, data: data, version: version, uuid: uuid, request_id: request_id),
                fifo: fifo, dest: dest, queue: queue
      end

      def publish_command(type, fifo:, dest: nil, data: {}, version: self.version, uuid: SecureRandom.uuid, request_id: nil, queue: nil)
        publish command(type, data: data, version: version, uuid: uuid, request_id: request_id),
                fifo: fifo, dest: dest, queue: queue
      end

      def create(queue)
        raise ArgumentError, 'Should be queue' unless queue.is_a? Resources::Queue
        raise Errors::QueueAlreadyExists.new(expected_queue: queue.name) if exists?(queue)

        attrs = {}
        attrs['FifoQueue'] = 'true' if queue.fifo

        aws_client.create_queue(queue_name: queue.name, attributes: attrs, tags: queue.tags)
        queue
      end

      def delete(queue)
        raise ArgumentError, 'Should be queue' unless queue.is_a? Resources::Queue
        raise Errors::QueueDoesNotExists.new(expected_queue: queue.name) unless exists?(queue)

        aws_client.delete_queue queue_url: queue.url
        queue
      end

      def list_all
        queues = []
        resp = aws_client.list_queues

        loop do
          next_token = resp[:next_token]

          resp[:queue_urls].map do |url|
            queues << Resources::Queue.from_url(url)
          end

          break if next_token.nil?

          resp = aws_client.list_queues(next_token: next_token)
        end

        queues
      end
    end
  end
end
