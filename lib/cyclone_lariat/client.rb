# frozen_string_literal: true

require 'aws-sdk-sns'
require 'luna_park/extensions/injector'
require_relative 'event'
require_relative 'errors'

module CycloneLariat
  class Client
    include LunaPark::Extensions::Injector

    dependency(:aws_sns_client_class)  { Aws::SNS::Client }
    dependency(:aws_credentials_class) { Aws::Credentials }

    DEFAULT_VERSION  = 1
    DEFAULT_INSTANCE = :prod
    SNS_SUFFIX       = :fanout

    def initialize(key:, secret_key:, region:, version: nil, publisher: nil, instance: nil)
      @key = key
      @secret_key = secret_key
      @region = region
      @version = version
      @publisher = publisher
      @instance = instance
    end

    def event(type, data: {}, version: self.version, uuid: SecureRandom.uuid)
      Event.wrap(
        uuid: uuid,
        type: type,
        sent_at: Time.now.iso8601,
        version: version,
        publisher: publisher,
        data: data
      )
    end

    def publish(msg, to: nil)
      topic = to || [instance, msg.kind, SNS_SUFFIX, publisher, msg.type].join('-')

      aws_client.publish(
        topic_arn: topic_arn(topic),
        message: msg.to_json
      )
    end

    def publish_event(type, data: {}, version: self.version, uuid: SecureRandom.uuid, to: nil)
      publish event(type, data: data, version: version, uuid: uuid), to: to
    end

    class << self
      def version(version = nil)
        version.nil? ? @version || DEFAULT_VERSION : @version = version
      end

      def instance(instance = nil)
        instance.nil? ? @instance || DEFAULT_INSTANCE : @instance = instance
      end

      def publisher(publisher = nil)
        publisher.nil? ? @publisher || (raise 'You should define publisher') : @publisher = publisher
      end
    end

    def self.publisher=
      # code here
    end

    private

    attr_reader :key, :secret_key, :region

    def version
      @version ||= self.class.version
    end

    def publisher
      @publisher ||= self.class.publisher
    end

    def instance
      @instance ||= self.class.instance
    end

    def topic_arn(topic_name)
      list  = aws_client.list_topics.topics
      topic = list.find { |t| t.topic_arn.match?(topic_name) }
      raise Errors::TopicNotFound.new(expected_topic: topic_name, existed_topics: list.map(&:topic_arn)) if topic.nil?

      topic.topic_arn
    end

    def aws_client
      @aws_client ||= aws_sns_client_class.new(credentials: aws_credentials, region: region)
    end

    def aws_credentials
      @aws_credentials ||= aws_credentials_class.new(key, secret_key)
    end
  end
end
