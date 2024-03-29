# frozen_string_literal: true

require 'forwardable'
require 'luna_park/extensions/injector'
require 'cyclone_lariat/plugins/outbox/repo/active_record/messages'
require 'cyclone_lariat/plugins/outbox/repo/sequel/messages'

module CycloneLariat
  class Outbox
    module Repo
      class Messages
        include LunaPark::Extensions::Injector

        dependency(:sequel_messages_class)        { Repo::Sequel::Messages }
        dependency(:active_record_messages_class) { Repo::ActiveRecord::Messages }
        dependency(:general_config)               { CycloneLariat.config }

        extend Forwardable

        def_delegators :driver, :transaction, :lock, :update_error, :create, :delete, :each_with_error

        def driver
          @driver ||= select_driver
        end

        private

        def select_driver
          case general_config.driver
          when :sequel        then sequel_messages_class.new(config.dataset)
          when :active_record then active_record_messages_class.new(config.dataset)
          else raise ArgumentError, "Undefined driver `#{general_config.driver}`"
          end
        end

        def config
          @config ||= CycloneLariat::Outbox.config
        end
      end
    end
  end
end
