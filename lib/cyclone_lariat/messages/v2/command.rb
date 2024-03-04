# frozen_string_literal: true

require 'cyclone_lariat/messages/abstract'
require 'cyclone_lariat/messages/v2/validator'

module CycloneLariat
  module Messages
    module V2
      class Command < Abstract
        validator Validator

        attrs :subject, :object

        KIND = 'command'

        def kind
          KIND
        end

        def serialize
          {
            uuid: uuid,
            publisher: publisher,
            type: [kind, type].join('_'),
            version: version,
            data: data,
            request_id: request_id,
            track_id: track_id,
            sent_at: sent_at&.iso8601(3),
            subject: subject,
            object: object
          }.compact
        end

        def subject
          @subject ||= {}
        end

        def object
          @object ||= {}
        end
      end
    end
  end
end
