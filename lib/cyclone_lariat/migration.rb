# frozen_string_literal: true

require 'fileutils'
require 'forwardable'
require_relative 'sns_client'
require_relative 'sqs_client'
require 'luna_park/errors'
require 'terminal-table'
require 'set'

module CycloneLariat
  class Migration
    extend Forwardable
    include LunaPark::Extensions::Injector

    dependency(:sns) { CycloneLariat::SnsClient.new }
    dependency(:sqs) { CycloneLariat::SqsClient.new }

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

    def subscribe(topic:, endpoint:)
      sns.subscribe topic: topic, endpoint: endpoint
      puts "  Subscription was created `#{topic.name} -> #{endpoint.name}`"
    end

    def unsubscribe(topic:, endpoint:)
      sns.unsubscribe topic: topic, endpoint: endpoint
      puts "  Subscription was deleted `#{topic.name} -> #{endpoint.name}`"
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
      when Topic then for_topic.call(resource)
      when Queue then for_queue.call(resource)
      else
        raise ArgumentError, "Unknown resource class #{resource.class}"
      end
    end

    class << self
      def migrate(dataset: CycloneLariat.versions_dataset, dir: DIR)
        alert('No one migration exists') if !Dir.exist?(dir) || Dir.empty?(dir)

        Dir.glob("#{dir}/*.rb") do |path|
          filename = File.basename(path, '.rb')
          version, title = filename.split('_', 2)

          existed_migrations = dataset.all.map { |row| row[:version] }
          unless existed_migrations.include? version.to_i
            class_name = title.split('_').collect(&:capitalize).join
            puts "Up - #{version} #{class_name} #{path}"
            require_relative Pathname.new(Dir.pwd) + Pathname.new(path)
            Object.const_get(class_name).new.up
            dataset.insert(version: version)
          end
        end
      end

      def rollback(version = nil, dataset: CycloneLariat.versions_dataset, dir: DIR)
        existed_migrations = dataset.all.map { |row| row[:version] }.sort
        version ||= existed_migrations[-1]
        migrations_to_downgrade = existed_migrations.select { |migration| migration >= version }

        paths = []
        migrations_to_downgrade.each do |migration|
          path = Pathname.new(Dir.pwd) + Pathname.new(dir)
          founded = Dir.glob("#{path}/#{migration}_*.rb")
          raise "Could not found migration: `#{migration}` in #{path}" if founded.empty?
          raise "Found lot of migration: `#{migration}` in #{path}"    if founded.size > 1

          paths += founded
        end

        paths.each do |path|
          filename       = File.basename(path, '.rb')
          version, title = filename.split('_', 2)
          class_name     = title.split('_').collect(&:capitalize).join
          puts "Down - #{version} #{class_name} #{path}"
          require_relative Pathname.new(Dir.pwd) + Pathname.new(path)
          Object.const_get(class_name).new.down
          dataset.filter(version: version).delete
        end
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
