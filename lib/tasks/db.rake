# frozen_string_literal: true

require 'sequel'
require_relative '../../config/db'

namespace :db do
  desc 'Create database'
  task create: :config do
    cmd = "PGPASSWORD=#{DB_CONF[:password]} createdb" \
          " --username=#{DB_CONF[:username]}" \
          " --host=#{DB_CONF[:host]}" \
          " #{DB_CONF[:database]}"
    puts "Database `#{DB_CONF[:database]}` successfully created" if system(cmd)
  end

  desc 'Drop database'
  task drop: :config do
    cmd = "PGPASSWORD=#{DB_CONF[:password]} dropdb" \
          " --username=#{DB_CONF[:username]}" \
          " --host=#{DB_CONF[:host]}" \
          " #{DB_CONF[:database]}"
    puts "Database `#{DB_CONF[:database]}` successfully dropped" if system(cmd)
  end

  desc 'Apply migrate'
  task :migrate, [:version] => :config do |_, args|
    require 'logger'
    require 'sequel/core'

    Sequel.extension :migration
    version = args[:version] ? args[:version].to_i : nil
    migrations_path = "#{__dir__}/../../db/migrate/"

    Sequel.connect(**DB_CONF, logger: Logger.new($stdout)) do |db|
      Sequel::Migrator.run(db, migrations_path, target: version)
    end
  end

  desc 'Database console'
  task console: :config do
    cmd = "PGPASSWORD=#{DB_CONF[:password]} psql" \
          " --username=#{DB_CONF[:username]}" \
          " --host=#{DB_CONF[:host]}" \
          " --port=#{DB_CONF[:port]}" \
          " #{DB_CONF[:database]}"
    puts "Database `#{DB_CONF[:database]}` says 'bye-bye'" if system(cmd)
  end

  desc 'Reset database - drop, create, & migrate'
  task :reset do
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
  end
end
