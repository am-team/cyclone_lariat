# frozen_string_literal: true

require 'terminal-table'

module CycloneLariat
  module Presenters
    class Queues
      HEADS = %w[valid region account_id name instance kind publisher type destination fifo].freeze

      def self.call(queues)
        new.call(queues)
      end

      def call(queues)
        rows = queues.map do |queue|
          row(queue)
        end

        Terminal::Table.new rows: rows, headings: HEADS
      end

      private

      def row(queue)
        [
          queue.custom? ? 'custom' : 'standard',
          queue.region,
          queue.account_id,
          queue.name,
          queue.instance,
          queue.kind,
          queue.publisher,
          queue.type,
          queue.dest,
          queue.fifo
        ]
      end
    end
  end
end
