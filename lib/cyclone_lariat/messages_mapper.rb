# frozen_string_literal: true

module CycloneLariat
  class MessagesMapper
    class << self
      def from_row(row)
        return if row.nil?

        row[:data] = hash_from_json_column(row[:data])
        row[:client_error_details] = hash_from_json_column(row[:client_error_details]) if row[:client_error_details]
        row
      end

      def to_row(input)
        {
          uuid: input.uuid,
          kind: input.kind,
          type: input.type,
          publisher: input.publisher,
          data: JSON.generate(input.data),
          client_error_message: input.client_error&.message,
          client_error_details: JSON.generate(input.client_error&.details),
          version: input.version,
          sent_at: input.sent_at
        }
      end

      private

      def hash_from_json_column(data)
        return JSON.parse(data) if data.is_a?(String)

        if pg_json_extension_enabled?
          return data.to_h             if data.is_a?(Sequel::Postgres::JSONHash)
          return JSON.parse(data.to_s) if data.is_a?(Sequel::Postgres::JSONString)
        end

        raise ArgumentError, "Unknown type of `#{data}`"
      end

      def pg_json_extension_enabled?
        Object.const_defined?('Sequel::Postgres::JSONHash')
      end
    end
  end
end
