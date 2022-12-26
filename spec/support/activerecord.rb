# frozen_string_literal: true

require 'active_record'
require 'database_cleaner-active_record'
require_relative '../../config/db'

ActiveRecord::Base.establish_connection(DB_CONF)

ActiveRecord::Base.connection.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"')
ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS ar_async_messages')
ActiveRecord::Base.connection.create_table(:ar_async_messages) do |t|
  t.integer :version, null: false, unique: true
end
ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS ar_lariat_versions')
ActiveRecord::Base.connection.create_table(:ar_lariat_versions) do |t|
  t.integer :version, null: false, unique: true
end
