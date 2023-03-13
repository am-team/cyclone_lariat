# frozen_string_literal: true

require 'cyclone_lariat/messages/v1/event'
require 'cyclone_lariat/messages/v1/command'
require 'cyclone_lariat/messages/builder'
require 'cyclone_lariat/plugins/outbox/mappers/messages'

module CycloneLariat
  module Outbox
    module Repo
      module ActiveRecord
        class Messages
          attr_reader :dataset, :republish_timeout

          def initialize(config)
            @dataset = config.dataset
            @republish_timeout = config.republish_timeout
          end

          def create(msg)
            dataset.create(Outbox::Mappers::Messages.to_row(msg)).uuid
          end

          def delete(uuid)
            dataset.where(uuid: uuid).delete_all
          end

          def update_error(uuid, error_message)
            dataset.where(uuid: uuid).update(sending_error: error_message)
          end

          def each_unpublished
            dataset
              .where('created_at < ?', Time.now - republish_timeout)
              .order(created_at: :asc)
              .each do |row|
              msg = build_message_from_ar_row(row)
              yield(msg)
            end
          end

          private

          def build_message_from_ar_row(row)
            build Outbox::Mappers::Messages.from_row(row.attributes.symbolize_keys)
          end

          def build(raw)
            CycloneLariat::Messages::Builder.new(raw_message: raw).call
          end
        end
      end
    end
  end
end
