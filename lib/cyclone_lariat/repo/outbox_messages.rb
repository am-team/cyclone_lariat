# frozen_string_literal: true

require 'forwardable'
require 'luna_park/extensions/injector'
require 'cyclone_lariat/core'
require 'cyclone_lariat/repo/sequel/messages'
require 'cyclone_lariat/repo/active_record/messages'

module CycloneLariat
  module Repo
    class OutboxMessages
      include LunaPark::Extensions::Injector

      attr_reader :config

      dependency(:sequel_messages_class) { Repo::Adapters::Sequel::OutboxMessages }
      dependency(:active_record_messages_class) { Repo::Adapters::ActiveRecord::OutboxMessages }

      extend Forwardable

      def_delegators :driver, :create, :exists?, :processed!, :find, :each_unprocessed, :each_with_client_errors,
                     :enabled?, :disabled?

      def initialize(**options)
        @config = CycloneLariat::Options.wrap(options).merge!(CycloneLariat.config)
      end

      def driver
        @driver ||= select(driver: config.db_driver)
      end

      private

      def select(driver:)
        case driver
        when :sequel then sequel_messages_class.new(config.inbox_dataset)
        when :active_record then active_record_messages_class.new(config.outbox_dataset)
        else raise ArgumentError, "Undefined driver `#{driver}`"
        end
      end
    end
  end
end
