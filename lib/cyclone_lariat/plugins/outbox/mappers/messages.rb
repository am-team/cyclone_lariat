# frozen_string_literal: true

require 'cyclone_lariat/repo/mappers/base'

module CycloneLariat
  class Outbox
    module Mappers
      class Messages < CycloneLariat::Repo::Mappers::Base
        class << self
          def from_row(row)
            return if row.nil?

            attrs = hash_from_json_column(row[:serialized_message]).symbolize_keys
            attrs[:uuid]             = row[:uuid]
            attrs[:deduplication_id] = row[:deduplication_id]
            attrs[:group_id]         = row[:group_id]
            attrs[:sending_error]    = row[:sending_error]

            attrs
          end

          def to_row(input)
            {}.tap do |row|
              row[:uuid] = input.uuid if input.uuid
              row[:deduplication_id] = input.deduplication_id
              row[:group_id] = input.group_id
              row[:serialized_message] = input.to_json
              row[:sending_error] = input.sending_error
            end
          end
        end
      end
    end
  end
end
