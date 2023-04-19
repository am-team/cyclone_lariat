# frozen_string_literal: true

require 'cyclone_lariat/messages/v1/event'
require 'cyclone_lariat/messages/v1/command'
require 'cyclone_lariat/messages/builder'
require 'cyclone_lariat/plugins/outbox/mappers/messages'

module CycloneLariat
  class Outbox
    module Repo
      module ActiveRecord
        class Messages
          LIMIT = 1000

          attr_reader :dataset

          def initialize(dataset)
            @dataset = dataset
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

          def each_with_error
            dataset
              .where('sending_error IS NOT NULL')
              .order(created_at: :asc)
              .limit(LIMIT)
              .each do |row|
                msg = build_message_from_ar_row(row)
                yield(msg)
              end
          end

          def transaction(&block)
            dataset.transaction(&block)
          end

          def lock(uuid)
            dataset.lock('FOR UPDATE NOWAIT').where(uuid: uuid)
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
