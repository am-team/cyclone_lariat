# frozen_string_literal: true

require 'cyclone_lariat/messages/v1/event'
require 'cyclone_lariat/messages/v1/command'
require 'cyclone_lariat/messages/v2/event'
require 'cyclone_lariat/messages/v2/command'

module CycloneLariat
  module Messages
    class Builder
      attr_reader :raw_message

      def initialize(raw_message:)
        @raw_message = raw_message.except(:kind)
      end

      def call
        case message_type
        when 'event' then event_builder
        when 'command' then command_builder
        else raise ArgumentError, "Unknown message type #{message_type}"
        end
      end

      private

      def event_builder
        case message_version
        when 1 then event_v1
        when 2 then event_v2
        else raise ArgumentError, "Unknown event message version #{message_version}"
        end
      end

      def command_builder
        case message_version
        when 1 then command_v1
        when 2 then command_v2
        else raise ArgumentError, "Unknown command message version #{message_version}"
        end
      end

      def event_v1
        Messages::V1::Event.wrap(@raw_message)
      end

      def event_v2
        Messages::V2::Event.wrap(@raw_message)
      end

      def command_v1
        Messages::V1::Command.wrap(@raw_message)
      end

      def command_v2
        Messages::V2::Command.wrap(@raw_message)
      end

      def message_version
        Integer(@raw_message[:version])
      end

      def message_type
        @raw_message[:type].split('_').first
      end
    end
  end
end
