# frozen_string_literal: true

module CycloneLariat
  module Plugins
    class Outbox
      class << self
        def config
          @config ||= OpenStruct.new
        end

        def configure
          yield(config)
        end

        def load
          extend_driver_transaction
        end

        private

        def check_config!
          raise ArgumentError, "Undefined outbox dataset"       unless config.outbox_dataset
          raise ArgumentError, "Undefined outbox poll interval" unless config.outbox_poll_interval
          raise ArgumentError, "Undefined async backend"        unless config.async_backend
        end

        def extend_driver_transaction
          case CycloneLariat.config.db_driver
          when :sequel        then Sequel::Database.prepend(Outbox::Extensions::Sequel)
          when :active_record then ActiveRecord::Base.prepend(Outbox::Extensions::ActiveRecord)
          else raise ArgumentError, "Undefined driver `#{driver}`"
          end
        end

        def config
          @config ||= CycloneLariat.config
        end
      end
    end
  end
end
