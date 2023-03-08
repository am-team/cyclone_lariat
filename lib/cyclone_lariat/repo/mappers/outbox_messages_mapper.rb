# frozen_string_literal: true

module CycloneLariat
  module Repo
    module Mappers
      class OutboxMessages
        class << self
          def from_row(row)
            return if row.nil?

            row = hash_from_json_column(row[:data])
            row
          end

          def to_row(input)
            {
              kind: input.kind,
              type: input.type,
              publisher: input.publisher,
              serialized_message: JSON.generate(input.serialize),
              error_message: input.client_error&.message,
              version: input.version
            }
          end
        end
      end
    end
  end
end
