# frozen_string_literal: true

require 'cyclone_lariat'

namespace :cyclone_lariat do
  desc 'Migrate topics for SQS\SNS'
  task migrate: :config do
    require_relative '../../config/initializers/cyclone_lariat'
    CycloneLariat::Migration.migrate
  end

  desc 'Rollback topics for SQS\SNS'
  task :rollback, [:version] => :config do |_, args|
    require_relative '../../config/initializers/cyclone_lariat'
    target_version = args[:version] ? args[:version].to_i : nil
    CycloneLariat::Migration.rollback(target_version)
  end
end
