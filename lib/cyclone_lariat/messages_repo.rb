# frozen_string_literal: true

require_relative 'event'
require_relative 'utils/hash'

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

      raw[:data] = hash_from_json_column(raw[:data])

      if raw[:client_error_details]
        raw[:client_error_details] = hash_from_json_column(raw[:client_error_details])
      end
      build raw
    end

    def each_unprocessed
      dataset.where(processed_at: nil).each do |raw|
        raw[:data] = hash_from_json_column(raw[:data])
        if raw[:client_error_details]
          raw[:client_error_details] = hash_from_json_column(raw[:client_error_details])
        end
        msg = build raw
        yield(msg)
      end
    end

    def each_with_client_errors
      dataset.where { (processed_at !~ nil) & (client_error_message !~ nil) }.each do |raw|
        raw[:data] = hash_from_json_column(raw[:data])
        if raw[:client_error_details]
          raw[:client_error_details] = hash_from_json_column(raw[:client_error_details])
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

    def hash_from_json_column(data)
      return JSON.parse(data, symbolize_names: true) if data.is_a?(String)

      if pg_json_extension_enabled?
        return Utils::Hash.deep_symbolize_keys(data.to_h)   if data.is_a?(Sequel::Postgres::JSONHash)
        return JSON.parse(data.to_s, symbolize_names: true) if data.is_a?(Sequel::Postgres::JSONString)
      end

      raise ArgumentError, "Unknown type of `#{data}`"
    end

    def pg_json_extension_enabled?
      Object.const_defined?('Sequel::Postgres::JSONHash')
    end
  end
end
