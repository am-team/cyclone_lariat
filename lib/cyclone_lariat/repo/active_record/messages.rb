# frozen_string_literal: true

require 'cyclone_lariat/messages/v1/event'
require 'cyclone_lariat/messages/v1/command'
require 'cyclone_lariat/repo/messages_mapper'

module CycloneLariat
  module Repo
    module ActiveRecord
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
          dataset.create(MessagesMapper.to_row(msg)).uuid
        end

        def exists?(uuid:)
          dataset.exists?(uuid: uuid)
        end

        def processed!(uuid:, error: nil)
          data = { processed_at: current_timestamp_from_db }
          data.merge!(client_error_message: error.message, client_error_details: JSON.generate(error.details)) if error

          message = dataset.where(uuid: uuid).first
          return false unless message

          message.update(data)
        end

        def find(uuid:)
          row = dataset.where(uuid: uuid).first
          return if row.nil?

          build MessagesMapper.from_row(row.attributes.symbolize_keys)
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

        def current_timestamp_from_db
          time_string_from_db =
            ::ActiveRecord::Base
            .connection.execute('select current_timestamp;')
            .first['current_timestamp']
          Time.parse(time_string_from_db)
        end

        def build(raw)
          case kind = raw.delete(:kind)
          when 'event'   then CycloneLariat::Messages::V1::Event.wrap raw
          when 'command' then CycloneLariat::Messages::V1::Command.wrap raw
          else raise ArgumentError, "Unknown kind `#{kind}` of message"
          end
        end
      end
    end
  end
end
