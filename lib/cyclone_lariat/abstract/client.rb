# frozen_string_literal: true

# require 'aws-sdk-sns'
require 'luna_park/extensions/injector'
require_relative '../event'
require_relative '../command'
require_relative '../errors'

module CycloneLariat
  module Abstract
    class Client
      include LunaPark::Extensions::Injector

      dependency(:aws_client_class)      { raise ArgumentError, 'Client class should be defined' }
      dependency(:aws_credentials_class) { Aws::Credentials }

      DEFAULT_VERSION  = 1
      DEFAULT_INSTANCE = :prod

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

      def command(type, data: {}, version: self.version, uuid: SecureRandom.uuid)
        Command.wrap(
          uuid: uuid,
          type: type,
          sent_at: Time.now.iso8601,
          version: version,
          publisher: publisher,
          data: data
        )
      end

      def publish
        raise LunaPark::Errors::AbstractMethod, 'Publish method should be defined'
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

      def version
        @version ||= self.class.version
      end

      def publisher
        @publisher ||= self.class.publisher
      end

      def instance
        @instance ||= self.class.instance
      end

      private

      attr_reader :key, :secret_key, :region

      def aws_client
        @aws_client ||= aws_client_class.new(credentials: aws_credentials, region: region)
      end

      def aws_credentials
        @aws_credentials ||= aws_credentials_class.new(key, secret_key)
      end
    end
  end
end
