# frozen_string_literal: true

require 'cyclone_lariat/messages/v1/event'
require 'cyclone_lariat/messages/v1/command'
require 'cyclone_lariat/repo/mappers/inbox_messages'
require 'cyclone_lariat/messages/builder'

module CycloneLariat
  module Repo
    module Sequel
      class InboxMessages
        attr_reader :dataset

        def initialize(dataset)
          @dataset = dataset
        end

        def enabled?
          !dataset.nil?
        end

        def disabled?
          dataset.nil?
        end

        def create(msg)
          dataset.insert Mappers::InboxMessages.to_row(msg)
        end

        def exists?(uuid:)
          dataset.where(uuid: uuid).limit(1).any?
        end

        def processed!(uuid:, error: nil)
          data = { processed_at: ::Sequel.function(:NOW) }
          if error
            data[:client_error_message] = error.message
            data[:client_error_details] = JSON.generate(error.details)
          end

          !dataset.where(uuid: uuid).update(data).zero?
        end

        def find(uuid:)
          row = dataset.where(uuid: uuid).first
          return if row.nil?

          build Mappers::InboxMessages.from_row(row)
        end

        def each_unprocessed
          dataset.where(processed_at: nil).each do |row|
            msg = build Mappers::InboxMessages.from_row(row)
            yield(msg)
          end
        end

        def each_with_client_errors
          dataset.where { (processed_at !~ nil) & (client_error_message !~ nil) }.each do |row|
            msg = build Mappers::InboxMessages.from_row(row)
            yield(msg)
          end
        end

        private

        def build(raw)
          CycloneLariat::Messages::Builder.new(raw_message: raw).call
        end
      end
    end
  end
end
