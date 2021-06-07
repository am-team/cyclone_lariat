# frozen_string_literal: true

require 'luna_park/errors/system'
require 'luna_park/errors/business'

module CycloneLariat
  module Errors
    class TopicNotFound < LunaPark::Errors::System
      message { |d| "Could not found topic: `#{d[:expected_topic]}`" }
    end

    class ClientError < LunaPark::Errors::Business
      attr_writer :message, :details

      def ==(other)
        other.is_a?(LunaPark::Errors::Business) &&
          other.message == message &&
          other.details == details
      end
    end
  end
end
