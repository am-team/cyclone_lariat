# frozen_string_literal: true

require 'singleton'

module CycloneLariat
  class ListTopicsStore
    include Singleton

    def topic_arn(topic_name)
      @topics[topic_name.to_sym]
    end

    def list
      @topics.keys
    end

    def add_topics(aws_client)
      @topics ||= {}
      @aws_client = aws_client
      fetch
    end

    def clear_store!
      @topics = {}
    end

    private

    def fetch
      return unless @topics.empty?

      @next_token = ''
      topics_from_aws until @next_token.nil?
    end

    def topics_from_aws
      result = @aws_client.list_topics(next_token: @next_token)
      @next_token = result.next_token
      result.topics.each do |topic|
        topic_name = topic.topic_arn.split(':').last
        @topics[topic_name.to_sym] = topic.topic_arn
      end
    end
  end
end
