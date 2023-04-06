# frozen_string_literal: true

require 'cyclone_lariat/messages/v1/event'
require 'cyclone_lariat/messages/v1/command'
require 'cyclone_lariat/messages/builder'
require 'cyclone_lariat/plugins/outbox/mappers/messages'

module CycloneLariat
  class Outbox
    module Repo
      module Sequel
        class Messages
          LIMIT = 1000

          attr_reader :dataset

          def initialize(dataset)
            @dataset = dataset
          end

          def create(msg)
            dataset.returning.insert(Outbox::Mappers::Messages.to_row(msg)).first[:uuid]
          end

          def delete(uuid)
            dataset.where(uuid: uuid).delete
          end

          def update_error(uuid, error_message)
            dataset.where(uuid: uuid).update(sending_error: error_message)
          end

          def each_with_error
            dataset
              .where { sending_error !~ nil }
              .order(::Sequel.asc(:created_at))
              .limit(LIMIT)
              .each do |row|
                msg = build Outbox::Mappers::Messages.from_row(row)
                yield(msg)
              end
          end

          def transaction(&block)
            dataset.db.transaction(&block)
          end

          def lock(uuid)
            dataset.where(uuid: uuid).for_update.nowait
          end

          private

          def build(raw)
            CycloneLariat::Messages::Builder.new(raw_message: raw).call
          end
        end
      end
    end
  end
end
