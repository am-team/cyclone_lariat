# frozen_string_literal: true

require 'forwardable'
require 'luna_park/extensions/injector'
require 'cyclone_lariat/core'
require 'cyclone_lariat/repo/sequel/messages'

module CycloneLariat
  module Repo
    class Messages
      include LunaPark::Extensions::Injector

      attr_reader :config

      dependency(:sequel_versions_class) { Repo::Sequel::Messages }
      dependency(:active_record_versions_class) { Repo::ActiveRecord::Messages }

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
        when :sequel then sequel_versions_class.new(config.versions_dataset)
        when :active_record then active_record_versions_class.new(config.versions_dataset)
        else raise ArgumentError, "Undefined driver `#{driver}`"
        end
      end
    end
  end
end
