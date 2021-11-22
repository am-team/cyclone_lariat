# frozen_string_literal: true

require_relative 'event'

module CycloneLariat
  class MessagesRepo
    attr_reader :dataset

    def initialize(dataset)
      @dataset = dataset
    end

    def create(msg)
      dataset.insert(
        uuid: msg.uuid,
        kind: msg.kind,
        type: msg.type,
        publisher: msg.publisher,
        data: JSON.generate(msg.data),
        client_error_message: msg.client_error&.message,
        client_error_details: JSON.generate(msg.client_error&.details),
        version: msg.version,
        sent_at: msg.sent_at
      )
    end

    def exists?(uuid:)
      dataset.where(uuid: uuid).limit(1).any?
    end

    def processed!(uuid:, error: nil)
      data = { processed_at: Sequel.function(:NOW) }
      data.merge!(client_error_message: error.message, client_error_details: JSON.generate(error.details)) if error

      !dataset.where(uuid: uuid).update(data).zero?
    end

    def find(uuid:)
      raw = dataset.where(uuid: uuid).first
      return nil unless raw

      
      raw[:data] = raw[:data].is_a?(String) ? JSON.parse(raw[:data], symbolize_names: true) : raw[:data].to_h
      if raw[:client_error_details]
        raw[:client_error_details] = JSON.parse(raw[:client_error_details], symbolize_names: true)
      end
      build raw
    end

    def each_unprocessed
      dataset.where(processed_at: nil).each do |raw|
        raw[:data]                 = JSON.parse(raw[:data], symbolize_names: true)
        if raw[:client_error_details]
          raw[:client_error_details] = JSON.parse(raw[:client_error_details], symbolize_names: true)
        end
        msg = build raw
        yield(msg)
      end
    end

    def each_with_client_errors
      dataset.where { (processed_at !~ nil) & (client_error_message !~ nil) }.each do |raw|
        raw[:data] = JSON.parse(raw[:data], symbolize_names: true)
        if raw[:client_error_details]
          raw[:client_error_details] = JSON.parse(raw[:client_error_details], symbolize_names: true)
        end
        msg = build raw
        yield(msg)
      end
    end

    private

    def build(raw)
      case kind = raw.delete(:kind)
      when 'event'   then Event.wrap raw
      when 'command' then Command.wrap raw
      else raise ArgumentError, "Unknown kind `#{kind}` of message"
      end
    end
  end
end
