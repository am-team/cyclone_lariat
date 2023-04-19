# frozen_string_literal: true

module CycloneLariat
  module Repo
    module Mappers
      class Base
        class << self
          private

          def hash_from_json_column(data)
            return data if data.is_a?(Hash)
            return JSON.parse(data) if data.is_a?(String)

            if pg_json_extension_enabled?
              return data.to_h             if data.is_a?(::Sequel::Postgres::JSONHash)
              return JSON.parse(data.to_s) if data.is_a?(::Sequel::Postgres::JSONString)
            end

            raise ArgumentError, "Unknown type of `#{data}`"
          end

          def pg_json_extension_enabled?
            Object.const_defined?('Sequel::Postgres::JSONHash')
          end
        end
      end
    end
  end
end
