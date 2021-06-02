# frozen_string_literal: true

require_relative 'event'

module CycloneLariat
  class EventsRepo
    attr_reader :dataset

    def initialize(dataset)
      @dataset = dataset
    end

    def create(event)
      dataset.insert(
        uuid: event.uuid,
        type: event.type,
        publisher: event.publisher,
        data: JSON.generate(event.data),
        error_message: event.error&.message,
        error_details: JSON.generate(event.error&.details),
        version: event.version,
        sent_at: event.sent_at
      )
    end

    def exists?(uuid:)
      dataset.where(uuid: uuid).limit(1).any?
    end

    def processed!(uuid:)
      !dataset.where(uuid: uuid).update(processed_at: Sequel.function(:NOW)).zero?
    end

    def find(uuid:)
      raw = dataset.where(uuid: uuid).first
      raw[:data]          = JSON.parse(raw[:data], symbolize_names: true)
      raw[:error_details] = JSON.parse(raw[:error_details], symbolize_names: true)
      Event.wrap raw
    end

    def each_unprocessed
      dataset.where(processed_at: nil).each do |raw|
        raw[:data]          = JSON.parse(raw[:data], symbolize_names: true)
        raw[:error_details] = JSON.parse(raw[:error_details], symbolize_names: true)
        event = Event.wrap(raw)
        yield(event)
      end
    end
  end
end
