# frozen_string_literal: true

require 'forwardable'
require 'luna_park/extensions/injector'
require 'cyclone_lariat/plugins/outbox/repo/active_record/messages'
require 'cyclone_lariat/plugins/outbox/repo/sequel/messages'

module CycloneLariat
  module Outbox
    module Repo
      class Messages
        include LunaPark::Extensions::Injector

        dependency(:sequel_messages_class)        { Repo::Sequel::Messages }
        dependency(:active_record_messages_class) { Repo::ActiveRecord::Messages }

        extend Forwardable

        def_delegators :driver, :update_error, :create, :delete, :each_unpublished

        def driver
          @driver ||= select(driver: CycloneLariat.config.driver)
        end

        private

        def select(driver:)
          case driver
          when :sequel        then sequel_messages_class.new(config)
          when :active_record then active_record_messages_class.new(config)
          else raise ArgumentError, "Undefined driver `#{driver}`"
          end
        end

        def config
          @config ||= CycloneLariat::Outbox.config
        end
      end
    end
  end
end
