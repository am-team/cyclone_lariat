# frozen_string_literal: true

module CycloneLariat
  class Outbox
    module Configurable
      CONFIG_ATTRS = %i[dataset on_sending_error].freeze

      def config
        @config ||= Struct.new(*CONFIG_ATTRS).new
      end

      def configure
        yield(config) if block_given?
        config
      end
    end
  end
end
