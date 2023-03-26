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
        when :sequel        then Sequel::Database.prepend(Outbox::Extensions::SequelTransaction)
        when :active_record then ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(Outbox::Extensions::ActiveRecordTransaction)
        else raise ArgumentError, "Undefined driver `#{driver}`"
        end
      end
    end
  end
end
