# frozen_string_literal: true

module CycloneLariat
  module Repo
    module Mappers
      class InboxMessages < Base
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
        end
      end
    end
  end
end
