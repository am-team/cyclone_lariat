# frozen_string_literal: true

require 'cyclone_lariat/messages/abstract'

module CycloneLariat
  module Messages
    class Common < Abstract
      KIND = 'unknown'

      attrs :subject, :object

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
