# frozen_string_literal: true

require 'luna_park/entities/attributable'
require_relative '../errors'

module CycloneLariat
  module Abstract
    class Message < LunaPark::Entities::Attributable
      attr :uuid,      String, :new
      attr :publisher, String, :new
      attr :type,      String, :new
      attr :client_error
      attr :version
      attr :data

      attr_reader :sent_at,
                  :processed_at,
                  :received_at

      def kind
        raise LunaPark::Errors::AbstractMethod
      end

      def version=(value)
        @version = Integer(value)
      end

      def sent_at=(value)
        @sent_at = wrap_time(value)
      end

      def received_at=(value)
        @received_at = wrap_time(value)
      end

      def processed_at=(value)
        @processed_at = wrap_time(value)
      end

      def client_error_message=(txt)
        return unless txt

        @client_error ||= Errors::ClientError.new
        @client_error.message = txt
      end

      def client_error_details=(details)
        return unless details

        @client_error ||= Errors::ClientError.new
        @client_error.details = details
      end

      def ==(other)
        kind == other.kind &&
          uuid == other.uuid &&
          publisher == other.publisher &&
          type == other.type &&
          client_error&.message == other.client_error&.message &&
          client_error&.details == other.client_error&.details &&
          version == other.version &&
          sent_at.to_i == other.sent_at.to_i &&
          received_at.to_i == other.received_at.to_i
        processed_at.to_i == other.processed_at.to_i
      end

      def to_json(*args)
        hash = serialize
        hash[:type] = [kind, hash[:type]].join '_'
        hash.to_json(*args)
      end

      private

      def wrap_time(value)
        case value
        when String   then Time.parse(value)
        when Time     then value
        when NilClass then nil
        else raise Argumentevent.rbError, "Unknown type `#{value.class}`"
        end
      end
    end
  end
end
