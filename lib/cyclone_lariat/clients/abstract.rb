# frozen_string_literal: true

# require 'aws-sdk-sns'
require 'luna_park/extensions/injector'
require_relative '../messages/event'
require_relative '../messages/command'
require_relative '../errors'
require_relative '../config'

module CycloneLariat
  module Clients
    class Abstract
      include LunaPark::Extensions::Injector

      dependency(:aws_client_class)      { raise ArgumentError, 'Client class should be defined' }
      dependency(:aws_credentials_class) { Aws::Credentials }

      def initialize(**options)
        @config = CycloneLariat::Config.wrap(options).merge!(CycloneLariat.config)
      end

      attr_reader :config

      def event(type, data: {}, version: config.version, request_id: nil, uuid: SecureRandom.uuid)
        params = {
          uuid: uuid,
          type: type,
          sent_at: Time.now.iso8601(3),
          version: version,
          publisher: config.publisher,
          data: data,
          request_id: request_id
        }

        Messages::Event.wrap(params.compact)
      end

      def command(type, data: {}, version: config.version, request_id: nil, uuid: SecureRandom.uuid)
        params = {
          uuid: uuid,
          type: type,
          sent_at: Time.now.iso8601(3),
          version: version,
          publisher: config.publisher,
          data: data,
          request_id: request_id
        }

        Messages::Command.wrap(params.compact)
      end

      def publish
        raise LunaPark::Errors::AbstractMethod, 'Publish method should be defined'
      end

      private

      def aws_client
        @aws_client ||= aws_client_class.new(credentials: aws_credentials, region: config.aws_region)
      end

      def aws_credentials
        @aws_credentials ||= aws_credentials_class.new(config.aws_key, config.aws_secret_key)
      end
    end
  end
end
