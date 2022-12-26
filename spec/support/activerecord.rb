# frozen_string_literal: true

require 'active_record'
require 'database_cleaner-active_record'

ActiveRecord::Base.establish_connection(DB_CONF)

ActiveRecord::Base.connection.create_table(:users) do |t|
  t.string :name
  t.text :avatar_data
end
