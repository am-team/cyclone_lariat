# frozen_string_literal: true

require 'cyclone_lariat/messages/v1/command'

module CycloneLariat
  module Generators
    module Command
      def command(type, version: config.version, **options)
        case version.to_i
        when 1 then command_v1(type, **options)
        else raise ArgumentError, "Unknown version #{version}"
        end
      end

      def command_v1(type, data: {}, request_id: nil, uuid: SecureRandom.uuid)
        params = {
          uuid: uuid,
          type: type,
          sent_at: Time.now.iso8601(3),
          version: 1,
          publisher: config.publisher,
          data: data,
          request_id: request_id
        }

        Messages::V1::Command.wrap(params.compact)
      end
    end
  end
end
