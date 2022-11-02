# frozen_string_literal: true

require 'luna_park/errors/system'
require 'luna_park/errors/business'

module CycloneLariat
  module Errors
    class EmptyMessage < LunaPark::Errors::System
      message 'Received message is empty'
    end

    class ClientError < LunaPark::Errors::Business
      attr_writer :message, :details

      def ==(other)
        other.is_a?(LunaPark::Errors::Business) &&
          other.message == message &&
          other.details == details
      end
    end

    class TopicAlreadyExists < LunaPark::Errors::System
      message { |d| "Topic already exists: `#{d[:expected_topic]}`" }
    end

    class TopicDoesNotExists < LunaPark::Errors::System
      message { |d| "Topic does not exists: `#{d[:expected_topic]}`" }
    end

    class QueueAlreadyExists < LunaPark::Errors::System
      message { |d| "Queue already exists: `#{d[:expected_queue]}`" }
    end

    class QueueDoesNotExists < LunaPark::Errors::System
      message { |d| "Queue does not exists: `#{d[:expected_queue]}`" }
    end
  end
end
