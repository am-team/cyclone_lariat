# frozen_string_literal: true

require_relative '../db'

require 'sequel'

DB = Sequel.connect(DB_CONF)
