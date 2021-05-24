require 'aws-sdk-sns'
require_relative 'event'

module CycloneLariat
  class Client
    DEFAULT_VERSION = 1

    def initialize(key:, secret_key:, region:, version: nil, publisher: nil)
      @key = key
      @secret_key = secret_key
      @region = region
      @version = version
      @publisher = publisher
    end

    def event(type, data: {})
      Event.wrap(
        uuid: SecureRandom.uuid,
        type: "event_#{type}",
        sent_at: Time.current.iso8601,
        version: version,
        publisher: publisher,
        data: data
      )
    end

    def publish(event, to:)
      aws_client.publish(
        topic_arn: topic_arn(to),
        message: event.to_json
      )
    end

    def publish_event(type, data: {}, to:)
      publish event(type, data: data), to: to
    end

    class << self
      def version(version = nil)
        version.nil? ? @version || DEFAULT_VERSION : @version = version
      end

      def publisher(publisher = nil)
        publisher.nil? ? @publisher || (raise 'You should define publisher') : @publisher = version
      end
    end

    private

    attr_reader :key, :secret_key, :region

    def version
      @version ||= self.class.version
    end

    def publisher
      @publisher ||= self.class.publisher
    end

    # По уму бы сделать так что если ошибка,
    # то показывать то име которое пытались ввести
    # и все очереди которые доступны
    def topic_arn(topic_name)
      aws_client.list_topics.topics.find { |topic| topic.topic_arn.match?(topic_name) }&.topic_arn
    end

    def aws_client
      @aws_client ||= Aws::SNS::Client.new(credentials: aws_credentials, region: region)
    end

    def aws_credentials
      @aws_credentials ||= Aws::Credentials.new(key, secret_key)
    end
  end
end
