# frozen_string_literal: true

require 'active_record'
require 'database_cleaner-active_record'
require_relative '../../config/db'

ActiveRecord::Base.establish_connection(DB_CONF)

ActiveRecord::Base.connection.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"')
ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS ar_async_messages')
ActiveRecord::Base.connection.create_table(:ar_async_messages, id: :uuid, default: -> { 'public.uuid_generate_v4()' }) do |t|
  t.string :kind, null: false
  t.string :type, null: false
  t.integer :version, null: false
  t.string :publisher, null: false
  t.jsonb :data, null: false
  t.string :client_error_message, null: true, default: nil
  t.jsonb :client_error_details, null: true, default: nil
  t.datetime :sent_at, null: true, default: nil
  t.datetime :received_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
  t.datetime :processed_at, null: true, default: nil
end
ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS ar_lariat_versions')
ActiveRecord::Base.connection.create_table(:ar_lariat_versions) do |t|
  t.integer :version, null: false, index: { unique: true }
end

class ArAsyncMessage < ActiveRecord::Base
end
class ArLariatVersion < ActiveRecord::Base
end
