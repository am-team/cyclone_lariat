# frozen_string_literal: true

module CycloneLariat
  class Outbox
    module Loadable
      def load
        extend_driver_transaction
      end

      private

      def extend_driver_transaction
        case CycloneLariat.config.driver
        when :sequel
          Sequel::Database.prepend(Outbox::Extensions::SequelOutbox)
        when :active_record
          ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(Outbox::Extensions::ActiveRecordOutbox)
        else
          raise ArgumentError, "Undefined driver `#{driver}`"
        end
      end
    end
  end
end
