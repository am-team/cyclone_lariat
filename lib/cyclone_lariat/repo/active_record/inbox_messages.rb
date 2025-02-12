# frozen_string_literal: true

require 'cyclone_lariat/messages/v1/event'
require 'cyclone_lariat/messages/v1/command'
require 'cyclone_lariat/repo/mappers/inbox_messages'
require 'cyclone_lariat/messages/builder'

module CycloneLariat
  module Repo
    module ActiveRecord
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
          dataset.create(Mappers::InboxMessages.to_row(msg)).uuid
        end

        def exists?(uuid:)
          dataset.exists?(uuid: uuid)
        end

        def processed!(uuid:, error: nil)
          data = { processed_at: current_timestamp_from_db }
          if error
            data[:client_error_message] = error.message
            data[:client_error_details] = JSON.generate(error.details)
          end

          message = dataset.where(uuid: uuid).first
          return false unless message

          message.update(data)
        end

        def find(uuid:)
          row = dataset.where(uuid: uuid).first
          return if row.nil?

          build_message_from_ar_row(row)
        end

        def each_unprocessed
          dataset.where(processed_at: nil).each do |row|
            msg = build_message_from_ar_row(row)
            yield(msg)
          end
        end

        def each_with_client_errors
          dataset
            .where.not(processed_at: nil)
            .where.not(client_error_message: nil)
            .each do |row|
              msg = build_message_from_ar_row(row)
              yield(msg)
            end
        end

        private

        def build_message_from_ar_row(row)
          build Mappers::InboxMessages.from_row(row.attributes.symbolize_keys)
        end

        def current_timestamp_from_db
          time_from_db =
            ::ActiveRecord::Base
            .connection.execute('select current_timestamp;')
            .first
          time = time_from_db.is_a?(Hash) ? time_from_db['current_timestamp'] : time_from_db[0]
          time.is_a?(Time) ? time : Time.parse(time)
        end

        def build(raw)
          CycloneLariat::Messages::Builder.new(raw_message: raw).call
        end
      end
    end
  end
end
