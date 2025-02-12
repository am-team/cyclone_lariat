# frozen_string_literal: true

require 'terminal-table'

module CycloneLariat
  module Presenters
    class Subscriptions
      HEADS = %w[topic endpoint subscription_arn].freeze

      def self.call(subscriptions)
        new.call(subscriptions)
      end

      def call(subscriptions)
        rows = subscriptions.map do |subscription|
          row(subscription)
        end

        Terminal::Table.new rows: rows, headings: HEADS
      end

      private

      def row(subscription)
        [
          subscription[:topic].name,
          subscription[:endpoint].name,
          subscription[:arn]
        ]
      end
    end
  end
end
