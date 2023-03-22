# frozen_string_literal: true

require 'luna_park/extensions/callable'
require 'luna_park/extensions/injector'
require 'cyclone_lariat/clients/sns'
require 'cyclone_lariat/plugins/outbox/repo/messages'

module CycloneLariat
  module Outbox
    module Services
      class Resend
        extend LunaPark::Extensions::Callable
        include LunaPark::Extensions::Injector

        dependency(:messages_repo)    { CycloneLariat::Outbox::Repo::Messages.new }
        dependency(:sns_client)       { CycloneLariat::Clients::Sns.new }
        dependency(:on_sending_error) { CycloneLariat::Outbox.config.on_sending_error }

        def call
          sended_message_uuids = []

          messages_repo.each_for_resending do |message|
            begin
              sns_client.publish message, fifo: message.fifo?
              sended_message_uuids << message.uuid
            rescue StandardError => e
              on_sending_error.call(message, e) if on_sending_error
              messages_repo.update_error(message.uuid, e.message)
              next
            end
          end

          messages_repo.delete(sended_message_uuids)
        end
      end
    end
  end
end
