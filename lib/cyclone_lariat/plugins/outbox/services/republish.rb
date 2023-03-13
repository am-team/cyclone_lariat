# frozen_string_literal: true

require 'luna_park/extensions/callable'
require 'cyclone_lariat/clients/sns'
require 'cyclone_lariat/plugins/outbox/repo/messages'

module CycloneLariat
  module Outbox
    module Services
      class Republish
        extend LunaPark::Extensions::Callable

        def call
          sended_message_uuids = []
          messages_repo.each_unpublished do |message|
            begin
              sns_client.publish message, fifo: message.fifo?
              sended_message_uuids << message.uuid
            rescue StandardError
              next
            end
          end

          messages_repo.delete(sended_message_uuids)
        end

        private

        def messages_repo
          @messages_repo ||= CycloneLariat::Outbox::Repo::Messages.new
        end

        def sns_client
          @sns_client ||= CycloneLariat::Clients::Sns.new
        end
      end
    end
  end
end
