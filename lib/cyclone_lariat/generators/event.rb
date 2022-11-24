# frozen_string_literal: true

require_relative '../messages/v1/event'

module CycloneLariat
  module Generators
    module Event
      def event(type, version: config.version, **options)
        case version.to_i
        when 1 then event_v1(type, **options)
        else raise ArgumentError, "Unknown version #{version}"
        end
      end

      def event_v1(type, data: {}, request_id: nil, uuid: SecureRandom.uuid)
        params = {
          uuid: uuid,
          type: type,
          sent_at: Time.now.iso8601(3),
          version: 1,
          publisher: config.publisher,
          data: data,
          request_id: request_id
        }

        Messages::V1::Event.wrap(params.compact)
      end
    end
  end
end
