# frozen_string_literal: true

require 'luna_park/extensions/injector'
require 'cyclone_lariat/generators/event'
require 'cyclone_lariat/generators/command'
require 'cyclone_lariat/errors'
require 'cyclone_lariat/core'

module CycloneLariat
  module Clients
    class Abstract
      include LunaPark::Extensions::Injector
      include Generators::Event
      include Generators::Command

      dependency(:aws_client_class)      { raise ArgumentError, 'Client class should be defined' }
      dependency(:aws_credentials_class) { Aws::Credentials }

      def initialize(**options)
        @config = CycloneLariat::Options.wrap(options).merge!(CycloneLariat.config)
      end

      attr_reader :config

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
