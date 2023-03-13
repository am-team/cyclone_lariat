# frozen_string_literal: true

require 'forwardable'
require 'luna_park/extensions/injector'
require 'cyclone_lariat/core'
require 'cyclone_lariat/repo/sequel/inbox_messages'
require 'cyclone_lariat/repo/active_record/inbox_messages'

module CycloneLariat
  module Repo
    class InboxMessages
      include LunaPark::Extensions::Injector

      attr_reader :config

      dependency(:sequel_messages_class) { Repo::Sequel::InboxMessages }
      dependency(:active_record_messages_class) { Repo::ActiveRecord::InboxMessages }

      extend Forwardable

      def_delegators :driver, :create, :exists?, :processed!, :find, :each_unprocessed, :each_with_client_errors,
                     :enabled?, :disabled?

      def initialize(**options)
        @config = CycloneLariat::Options.wrap(options).merge!(CycloneLariat.config)
      end

      def driver
        @driver ||= select(driver: config.driver)
      end

      private

      def select(driver:)
        case driver
        when :sequel then sequel_messages_class.new(config.inbox_dataset)
        when :active_record then active_record_messages_class.new(config.inbox_dataset)
        else raise ArgumentError, "Undefined driver `#{driver}`"
        end
      end
    end
  end
end
