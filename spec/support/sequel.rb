# frozen_string_literal: true

require 'sequel'
require 'database_cleaner-sequel'
require_relative '../../config/db'

DB = Sequel.connect(DB_CONF)

DB.run('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"')
DB.drop_table?(:sequel_async_messages)
DB.create_table :sequel_async_messages do
  column :uuid, :uuid, primary_key: true
  String :kind, null: false
  String :type, null: false
  Integer :version, null: false
  String :publisher, null: false
  column :data, :json, null: false
  String :client_error_message, null: true, default: nil
  column :client_error_details, :json, null: true, default: nil
  DateTime :sent_at, null: true, default: nil
  DateTime :received_at, null: false, default: Sequel::CURRENT_TIMESTAMP
  DateTime :processed_at, null: true, default: nil
end
DB.drop_table?(:sequel_lariat_versions)
DB.create_table :sequel_lariat_versions do
  Integer :version, null: false, unique: true
end

DatabaseCleaner[:sequel, db: DB]
