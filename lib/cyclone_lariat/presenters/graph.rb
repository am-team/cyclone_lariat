# frozen_string_literal: true

require 'set'

module CycloneLariat
  module Presenters
    class Graph
      HEADS = %w[topic endpoint subscription_arn].freeze
      def self.call(subscriptions)
        new.call(subscriptions)
      end

      def call(subscriptions)
        return '' if subscriptions.empty?

        resources_set = Set.new

        subscriptions.each do |subscription|
          resources_set << subscription[:topic]
          resources_set << subscription[:endpoint]
        end

        [].tap do |output|
          output << open_graph

          resources_set.each { |resource| output << present_resource(resource) }
          subscriptions.each { |subscription| output << present_subscription(subscription) }

          output << close_graph
        end
      end

      private

      def present_resource(resource)
        color = resource.custom? ? ', fillcolor=grey' : ', fillcolor=white'
        style = resource.topic? ? "[shape=component style=filled#{color}]" : "[shape=record, style=\"rounded,filled\"#{color}]"
        "  \"#{resource.name}\" #{style};"
      end

      def present_subscription(subscription)
        "  \"#{subscription[:topic].name}\" -> \"#{subscription[:endpoint].name}\";"
      end

      def open_graph
        "digraph G {\n  rankdir=LR;"
      end

      def close_graph
        '}'
      end
    end
  end
end
