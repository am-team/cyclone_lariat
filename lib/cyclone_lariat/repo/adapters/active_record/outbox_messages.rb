# frozen_string_literal: true

require 'cyclone_lariat/messages/v1/event'
require 'cyclone_lariat/messages/v1/command'
require 'cyclone_lariat/repo/mappers/outbox_messages'
require 'cyclone_lariat/messages/builder'

module CycloneLariat
  module Repo
    module Adapters
      module ActiveRecord
        class OutboxMessages
          attr_reader :dataset, :visible_to_retry_after

          def initialize(dataset, visible_to_retry_after)
            @dataset = dataset
            @visible_to_retry_after = visible_to_retry_after
          end

          def enabled?
            !dataset.nil?
          end

          def disabled?
            dataset.nil?
          end

          def create(msg)
            dataset.create(Mappers::OutboxMessages.to_row(msg)).uuid
          end

          def each_to_retry
            dataset.where('created_at < ?', Time.now - visible_to_retry_after).each do |row|
              msg = build_message_from_ar_row(row)
              yield(msg)
            end
          end

          private

          def build_message_from_ar_row(row)
            build Mappers::OutboxMessages.from_row(row.attributes.symbolize_keys)
          end

          def build(raw)
            CycloneLariat::Messages::Builder.new(raw_message: raw).call
          end
        end
      end
    end
  end
end
