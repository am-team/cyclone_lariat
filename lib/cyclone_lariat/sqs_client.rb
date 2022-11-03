# frozen_string_literal: true

require 'aws-sdk-sqs'
require_relative 'abstract/client'
require_relative 'queue'

module CycloneLariat
  class SqsClient < Abstract::Client
    include LunaPark::Extensions::Injector

    dependency(:aws_client_class) { Aws::SQS::Client }

    def custom_queue(name)
      Queue.from_name(name, account_id: account_id, region: region)
    end

    def queue(type = :all, fifo:, dest: nil, kind: :event)
      Queue.new(instance: instance, publisher: publisher, region: region, account_id: account_id, kind: kind, type: type, fifo: fifo, dest: dest)
    end

    def get_url(queue)
      raise ArgumentError, 'Should be queue' unless queue.is_a? Queue

      aws_client.get_queue_url(queue_name: queue.to_s).queue_url
    end

    def exists?(queue)
      raise ArgumentError, 'Should be queue' unless queue.is_a? Queue

      get_url(queue) && true
    rescue Aws::SQS::Errors::NonExistentQueue
      false
    end

    def publish(msg, fifo:, dest: nil, queue: nil)
      queue = queue ? custom_queue(queue) : queue(msg.type, kind: msg.kind, fifo: fifo, dest: dest)
      aws_client.send_message( queue_url: get_url(queue), message_body: msg.to_json )
    end

    def create(queue)
      raise ArgumentError, 'Should be queue' unless queue.is_a? Queue
      raise Errors::QueueAlreadyExists.new(expected_queue: queue.name) if exists?(queue)

      attrs = {}
      attrs['FifoQueue'] = 'true' if queue.fifo

      aws_client.create_queue(queue_name: queue.name, attributes: attrs, tags: queue.tags)
      queue
    end

    def delete(queue)
      raise ArgumentError, 'Should be queue' unless queue.is_a? Queue
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
          queues << Queue.from_url(url)
        end

        break if next_token.nil?

        resp = aws_client.list_queues(next_token: next_token)
      end
      
      queues
    end
  end
end
