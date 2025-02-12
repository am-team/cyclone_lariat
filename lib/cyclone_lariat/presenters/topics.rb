# frozen_string_literal: true

require 'terminal-table'

module CycloneLariat
  module Presenters
    class Topics
      HEADS = %w[valid region account_id name instance kind publisher type fifo].freeze

      def self.call(topics)
        new.call(topics)
      end

      def call(topics)
        rows = topics.map do |topic|
          row(topic)
        end

        Terminal::Table.new rows: rows, headings: HEADS
      end

      private

      def row(topic)
        [
          topic.custom? ? 'custom' : 'standard',
          topic.region,
          topic.account_id,
          topic.name,
          topic.instance,
          topic.kind,
          topic.publisher,
          topic.type,
          topic.fifo
        ]
      end
    end
  end
end
