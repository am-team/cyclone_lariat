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
        client_error_message: event.client_error&.message,
        client_error_details: JSON.generate(event.client_error&.details),
        version: event.version,
        sent_at: event.sent_at
      )
    end

    def exists?(uuid:)
      dataset.where(uuid: uuid).limit(1).any?
    end

    def processed!(uuid:, error: nil)
      data = { processed_at: Sequel.function(:NOW) }
      data.merge!(
        client_error_message: error&.message,
        client_error_details: JSON.generate(error&.details),
      ) if error

      !dataset.where(uuid: uuid).update(data).zero?
    end

    def find(uuid:)
      raw = dataset.where(uuid: uuid).first
      raw[:data]                 = JSON.parse(raw[:data], symbolize_names: true)
      raw[:client_error_details] = JSON.parse(raw[:client_error_details], symbolize_names: true) if raw[:client_error_details]
      Event.wrap raw
    end

    def each_unprocessed
      dataset.where(processed_at: nil).each do |raw|
        raw[:data]                 = JSON.parse(raw[:data], symbolize_names: true)
        raw[:client_error_details] = JSON.parse(raw[:client_error_details], symbolize_names: true) if raw[:client_error_details]
        event = Event.wrap(raw)
        yield(event)
      end
    end

    def each_with_client_errors
      dataset.where { (processed_at !~ nil) & (client_error_message !~ nil) }.each do |raw|
        raw[:data]                 = JSON.parse(raw[:data], symbolize_names: true)
        raw[:client_error_details] = JSON.parse(raw[:client_error_details], symbolize_names: true) if raw[:client_error_details]
        event = Event.wrap(raw)
        yield(event)
      end
    end
  end
end
