# frozen_string_literal: true

require 'fileutils'
require 'forwardable'
require 'cyclone_lariat/clients/sns'
require 'cyclone_lariat/clients/sqs'
require 'cyclone_lariat/repo/versions'
require 'cyclone_lariat/services/migrate'
require 'cyclone_lariat/services/rollback'
require 'luna_park/errors'
require 'terminal-table'
require 'set'

module CycloneLariat
  class Migration
    extend Forwardable
    include LunaPark::Extensions::Injector

    dependency(:sns) { CycloneLariat::Clients::Sns.new }
    dependency(:sqs) { CycloneLariat::Clients::Sqs.new }

    DIR = './lariat/migrate'

    def up
      raise LunaPark::Errors::Abstract, "Up method should be defined in #{self.class.name}"
    end

    def down
      raise LunaPark::Errors::Abstract, "Down method should be defined in #{self.class.name}"
    end

    def_delegators :sqs, :queue, :custom_queue
    def_delegators :sns, :topic, :custom_topic

    def create(resource)
      process(
        resource: resource,
        for_topic: ->(topic) { sns.create(topic) },
        for_queue: ->(queue) { sqs.create(queue) }
      )

      puts "  #{resource.class.name.split('::').last} was created `#{resource.name}`"
    end

    def delete(resource)
      process(
        resource: resource,
        for_topic: ->(topic) { sns.delete(topic) },
        for_queue: ->(queue) { sqs.delete(queue) }
      )
      puts "  #{resource.class.name.split('::').last} was deleted `#{resource.name}`"
    end

    def exists?(resource)
      process(
        resource: resource,
        for_topic: ->(topic) { sns.exists?(topic) },
        for_queue: ->(queue) { sqs.exists?(queue) }
      )
    end

    def subscribe(topic:, endpoint:, policy: nil)
      policy ||= default_policy(topic, endpoint)
      sqs.add_policy(queue: endpoint, policy: policy) if endpoint.queue?
      sns.subscribe topic: topic, endpoint: endpoint
      puts "  Subscription was created `#{topic.name} -> #{endpoint.name}`"
    end

    def unsubscribe(topic:, endpoint:)
      sns.unsubscribe topic: topic, endpoint: endpoint
      puts "  Subscription was deleted `#{topic.name} -> #{endpoint.name}`"
    end

    def default_policy(topic, queue)
      {
        'Sid' => topic.name,
        'Effect' => 'Allow',
        'Principal' => {
          'AWS' => CycloneLariat.config.aws_account_id.to_s
        },
        'Action' => 'SQS:*',
        'Resource' => queue.arn,
        'Condition' => {
          'ArnEquals' => {
            'aws:SourceArn' => topic.arn
          }
        }
      }
    end

    def topics
      sns.list_all
    end

    def queues
      sqs.list_all
    end

    def subscriptions
      sns.list_subscriptions
    end

    private

    def process(resource:, for_topic:, for_queue:)
      case resource
      when Resources::Topic then for_topic.call(resource)
      when Resources::Queue then for_queue.call(resource)
      else
        raise ArgumentError, "Unknown resource class #{resource.class}"
      end
    end

    class << self
      def migrate(repo: CycloneLariat::Versions::Repo.new, dir: DIR)
        Services::Migrate.new(repo: repo, dir: dir).call
      end

      def rollback(version = nil, dataset: CycloneLariat.versions_dataset, dir: DIR)
        Services::Rollback.new(version, repo: repo, )
      end

      def list_topics
        rows = []
        new.topics.each do |topic|
          rows << [
            topic.custom? ? 'custom' : 'standard',
            topic.region,
            topic.account_id,
            topic.name,
            topic.instance,
            topic.kind,
            topic.publisher,
            topic.type,
            topic.fifo
          ]
        end

        puts Terminal::Table.new rows: rows, headings: %w[valid region account_id name instance kind publisher type fifo]
      end

      def list_queues
        rows = []
        new.queues.each do |queue|
          rows << [
            queue.custom? ? 'custom' : 'standard',
            queue.region,
            queue.account_id,
            queue.name,
            queue.instance,
            queue.kind,
            queue.publisher,
            queue.type,
            queue.dest,
            queue.fifo
          ]
        end

        puts Terminal::Table.new rows: rows, headings: %w[valid region account_id name instance kind publisher type destination fifo]
      end

      def list_subscriptions
        rows = []
        new.subscriptions.each do |subscription|
          rows << [
            subscription[:topic].name,
            subscription[:endpoint].name,
            subscription[:arn]
          ]
        end

        puts Terminal::Table.new rows: rows, headings: %w[topic endpoint subscription_arn]
      end

      def build_graph
        subscriptions = new.subscriptions
        resources_set = Set.new

        subscriptions.each do |subscription|
          resources_set << subscription[:topic]
          resources_set << subscription[:endpoint]
        end

        puts 'digraph G {'
        puts '  rankdir=LR;'

        resources_set.each do |resource|
          color = resource.custom? ? ', fillcolor=grey' : ', fillcolor=white'
          style = resource.topic? ? "[shape=component style=filled#{color}]" : "[shape=record, style=\"rounded,filled\"#{color}]"
          puts "  \"#{resource.name}\" #{style};"
        end

        subscriptions.each do |subscription|
          puts "  \"#{subscription[:topic].name}\" -> \"#{subscription[:endpoint].name}\";"
        end
        puts '}'
      end
    end
  end
end
