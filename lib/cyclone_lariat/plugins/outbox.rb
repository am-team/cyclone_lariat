# frozen_string_literal: true

require 'cyclone_lariat/core'
require 'cyclone_lariat/clients/sns'
require 'cyclone_lariat/plugins/outbox/options'
require 'cyclone_lariat/plugins/outbox/extensions/active_record_transaction'
require 'cyclone_lariat/plugins/outbox/extensions/sequel_transaction'

module CycloneLariat
  module Outbox
    class << self
      def config
        @config ||= Outbox::Options.new
      end

      def configure
        yield(config)
        extend_driver_transaction
      end

      private

      def extend_driver_transaction
        case CycloneLariat.config.driver
        when :sequel        then Sequel::Database.prepend(Outbox::Extensions::SequelTransaction)
        when :active_record then ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(Outbox::Extensions::ActiveRecordTransaction)
        else raise ArgumentError, "Undefined driver `#{driver}`"
        end
      end
    end
  end
end
