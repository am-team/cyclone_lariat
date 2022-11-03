# frozen_string_literal: true

require 'cyclone_lariat'

namespace :cyclone_lariat do
  desc 'Migrate topics for SQSSNS'
  task migrate: :config do
    require_relative '../../config/initializers/cyclone_lariat'
    CycloneLariat::Migration.migrate
  end

  desc 'Rollback topics for SQSSNS'
  task :rollback, [:version] => :config do |_, args|
    require_relative '../../config/initializers/cyclone_lariat'
    target_version = args[:version] ? args[:version].to_i : nil
    CycloneLariat::Migration.rollback(target_version)
  end

  namespace :list do
    desc 'List all topics'
    task :topics do
      require_relative '../../config/initializers/cyclone_lariat'
      CycloneLariat::Migration.list_topics
    end

    desc 'List all queues'
    task :queues do
      require_relative '../../config/initializers/cyclone_lariat'
      CycloneLariat::Migration.list_queues
    end

    desc 'List all subscriptions'
    task :subscriptions do
      require_relative '../../config/initializers/cyclone_lariat'
      CycloneLariat::Migration.list_subscriptions
    end
  end
end
