# frozen_string_literal: true

require 'luna_park/entities/attributable'
require 'luna_park/extensions/validatable'
require 'cyclone_lariat/errors'

module CycloneLariat
  module Messages
    class Abstract < LunaPark::Entities::Attributable
      include LunaPark::Extensions::Validatable

      KIND = 'unknown'

      attr :uuid,      String, :new
      attr :publisher, String, :new
      attr :type,      String, :new

      attrs :client_error, :sending_error, :version, :data, :request_id, :sent_at,
            :deduplication_id, :group_id, :processed_at, :received_at

      # Make validation public
      def validation # rubocop:disable Lint/UselessMethodDefinition
        super
      end

      def kind
        KIND
      end

      def serialize
        {
          uuid: uuid,
          publisher: publisher,
          type: [kind, type].join('_'),
          version: version,
          data: data,
          request_id: request_id,
          sent_at: sent_at&.iso8601(3)
        }.compact
      end

      def to_json(*args)
        serialize.to_json(*args)
      end

      def params
        serialize
      end

      def data
        @data ||= {}
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

      def request_id=(value)
        @request_id = wrap_string(value)
      end

      def group_id=(value)
        @group_id = wrap_string(value)
      end

      def deduplication_id=(value)
        @deduplication_id = wrap_string(value)
      end

      def processed?
        !@processed_at.nil?
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

      def fifo?
        !@group_id.nil?
      end

      def ==(other)
        kind == other.kind &&
          uuid == other.uuid &&
          publisher == other.publisher &&
          type == other.type &&
          client_error&.message == other.client_error&.message &&
          version == other.version &&
          sent_at.to_i == other.sent_at.to_i &&
          received_at.to_i == other.received_at.to_i &&
          processed_at.to_i == other.processed_at.to_i
      end

      private

      def wrap_time(value)
        case value
        when String   then Time.parse(value)
        when Time     then value
        when NilClass then nil
        else raise ArgumentError, "Unknown type `#{value.class}`"
        end
      end

      def wrap_string(value)
        case value
        when String, Integer
          String(value)
        when NilClass, FalseClass
          nil
        else
          raise ArgumentError, "Unknown type `#{value.class}`"
        end
      end
    end
  end
end
