# frozen_string_literal: true

require 'cyclone_lariat/messages/v1/event'
require 'cyclone_lariat/messages/v1/command'
require 'cyclone_lariat/messages/v2/event'
require 'cyclone_lariat/messages/v2/command'
require 'cyclone_lariat/messages/common'

module CycloneLariat
  module Messages
    class Builder
      attr_reader :raw_message

      def initialize(raw_message:)
        @raw_message = raw_message
        @kind = kind
        @raw_message[:type] = message_type
      end

      def call
        case @kind
        when 'event' then event_builder
        when 'command' then command_builder
        else Messages::Common.wrap(message_without_kind)
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
        Messages::V1::Event.wrap(message_without_kind)
      end

      def event_v2
        Messages::V2::Event.wrap(message_without_kind)
      end

      def command_v1
        Messages::V1::Command.wrap(message_without_kind)
      end

      def command_v2
        Messages::V2::Command.wrap(message_without_kind)
      end

      def message_version
        Integer(@raw_message[:version])
      end

      def message_without_kind
        @raw_message.except(:kind)
      end

      def kind
        return @raw_message[:kind] if @raw_message[:kind]

        @raw_message[:type].split('_').first
      end

      def message_type
        return @raw_message[:type] if @raw_message[:kind]

        @raw_message[:type].gsub(/^(event_|command_)/, '')
      end
    end
  end
end
