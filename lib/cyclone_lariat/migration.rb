# frozen_string_literal: true

require 'fileutils'
require 'forwardable'
require 'cyclone_lariat/clients/sns'
require 'cyclone_lariat/clients/sqs'
require 'cyclone_lariat/repo/versions'
require 'cyclone_lariat/services/migrate'
require 'cyclone_lariat/services/rollback'
require 'cyclone_lariat/presenters/topics'
require 'cyclone_lariat/presenters/queues'
require 'cyclone_lariat/presenters/subscriptions'
require 'cyclone_lariat/presenters/graph'
require 'luna_park/errors'

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
      policy ||= default_policy(endpoint)
      sqs.add_policy(queue: endpoint, policy: policy) if endpoint.queue?
      sns.subscribe topic: topic, endpoint: endpoint
      puts "  Subscription was created `#{topic.name} -> #{endpoint.name}`"
    end

    def unsubscribe(topic:, endpoint:)
      sns.unsubscribe topic: topic, endpoint: endpoint
      puts "  Subscription was deleted `#{topic.name} -> #{endpoint.name}`"
    end

    def default_policy(queue)
      {
        'Sid' => queue.arn,
        'Effect' => 'Allow',
        'Principal' => {
          'AWS' => '*'
        },
        'Action' => 'SQS:*',
        'Resource' => queue.arn,
        'Condition' => {
          'ArnEquals' => {
            'aws:SourceArn' => fanout_arn_pattern
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

    def fanout_arn_pattern
      @fanout_arn_pattern ||= [
        'arn:aws:sns',
        CycloneLariat.config.aws_region,
        CycloneLariat.config.aws_account_id,
        "#{CycloneLariat.config.instance}-*-fanout-*"
      ].join(':')
    end

    class << self
      def migrate(repo: CycloneLariat::Repo::Versions.new, dir: DIR, service: Services::Migrate)
        puts service.new(repo: repo, dir: dir).call
      end

      def rollback(version = nil, repo: CycloneLariat::Repo::Versions.new, dir: DIR, service: Services::Rollback)
        puts service.new(repo: repo, dir: dir).call(version)
      end

      def list_topics(presenter: Presenters::Topics)
        puts presenter.call(new.topics)
      end

      def list_queues(presenter: Presenters::Queues)
        puts presenter.call(new.queues)
      end

      def list_subscriptions(presenter: Presenters::Subscriptions)
        puts presenter.call(new.subscriptions)
      end

      def build_graph(presenter: Presenters::Graph)
        puts presenter.call(new.subscriptions)
      end
    end
  end
end
