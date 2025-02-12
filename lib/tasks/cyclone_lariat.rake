# frozen_string_literal: true

require 'cyclone_lariat'

namespace :cyclone_lariat do
  desc 'Migrate topics for SQS/SNS'
  task migrate: :config do
    CycloneLariat::Migration.migrate
  end

  desc 'Rollback topics for SQS/SNS'
  task :rollback, [:version] => :config do |_, args|
    target_version = args[:version]&.to_i
    CycloneLariat::Migration.rollback(target_version)
  end

  namespace :list do
    desc 'List all topics'
    task topics: :config do
      CycloneLariat::Migration.list_topics
    end

    desc 'List all queues'
    task queues: :config do
      CycloneLariat::Migration.list_queues
    end

    desc 'List all subscriptions'
    task subscriptions: :config do
      CycloneLariat::Migration.list_subscriptions
    end
  end

  desc 'Build graphviz graph for whole system'
  task graph: :config do
    CycloneLariat::Migration.build_graph
  end

  task :config do
    require_relative '../../config/initializers/cyclone_lariat'
  end
end
