# frozen_string_literal: true

require 'bundler/setup'
require 'pry'
require 'sequel'
require 'database_cleaner-sequel'

require_relative '../config/db'

DB = Sequel.connect(DB_CONF)
db_cleaner = DatabaseCleaner[:sequel, db: DB]

RSpec.configure do |config|
  config.color     = true
  config.formatter = :documentation

  config.mock_with   :rspec
  config.expect_with :rspec

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
  config.filter_run_when_matching(:focus) unless ENV['CI']

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Database cleaner
  config.before(:suite) { db_cleaner.clean_with :truncation }

  config.before do
    db_cleaner.strategy = self.class.metadata[:clean_with] || :transaction
  end

  config.before { db_cleaner.start }
  config.after  { db_cleaner.clean }
  config.after(:suite) { db_cleaner.clean_with :truncation }
end
