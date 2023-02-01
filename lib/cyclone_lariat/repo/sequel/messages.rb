# frozen_string_literal: true

require 'cyclone_lariat/messages/message'
require 'cyclone_lariat/repo/messages_mapper'

module CycloneLariat
  module Repo
    module Sequel
      class Messages
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
          dataset.insert MessagesMapper.to_row(msg)
        end

        def exists?(uuid:)
          dataset.where(uuid: uuid).limit(1).any?
        end

        def processed!(uuid:, error: nil)
          data = { processed_at: ::Sequel.function(:NOW) }
          data.merge!(client_error_message: error.message, client_error_details: JSON.generate(error.details)) if error

          !dataset.where(uuid: uuid).update(data).zero?
        end

        def find(uuid:)
          row = dataset.where(uuid: uuid).first
          return if row.nil?

          build MessagesMapper.from_row(row)
        end

        def each_unprocessed
          dataset.where(processed_at: nil).each do |row|
            msg = build MessagesMapper.from_row(row)
            yield(msg)
          end
        end

        def each_with_client_errors
          dataset.where { (processed_at !~ nil) & (client_error_message !~ nil) }.each do |row|
            msg = build MessagesMapper.from_row(row)
            yield(msg)
          end
        end

        private

        def build(raw)
          CycloneLariat::Messages::Message.wrap(raw)
        end
      end
    end
  end
end
