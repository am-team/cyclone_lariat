# frozen_string_literal: true

require_relative 'event'
require_relative 'messages_mapper'

module CycloneLariat
  class MessagesRepo
    attr_reader :dataset

    def initialize(dataset)
      @dataset = dataset
    end

    def create(msg)
      dataset.insert MessagesMapper.to_row(msg)
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
      row = dataset.where(uuid: uuid).first
      build MessagesMapper.from_row(row)
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

    def build(raw)
      case kind = raw.delete(:kind)
      when 'event'   then Event.wrap raw
      when 'command' then Command.wrap raw
      else raise ArgumentError, "Unknown kind `#{kind}` of message"
      end
    end
  end
end
