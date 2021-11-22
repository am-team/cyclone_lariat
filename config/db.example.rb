# frozen_string_literal: true

DB_CONF = {
  adapter: 'postgresql',
  host: ENV.fetch('DB_HOST', 'host'),
  username: ENV.fetch('DB_USER', 'postgres'),
  password: ENV.fetch('DB_PASSWORD', 'password'),
  database: ENV.fetch('DB_NAME', 'cyclone-lariat-test'
}.freeze
