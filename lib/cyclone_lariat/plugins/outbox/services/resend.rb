# frozen_string_literal: true

require 'luna_park/extensions/callable'
require 'luna_park/extensions/injector'
require 'cyclone_lariat/clients/sns'
require 'cyclone_lariat/plugins/outbox/repo/messages'

module CycloneLariat
  class Outbox
    module Services
      class Resend
        extend LunaPark::Extensions::Callable
        include LunaPark::Extensions::Injector

        dependency(:messages_repo)    { CycloneLariat::Outbox::Repo::Messages.new }
        dependency(:sns_client)       { CycloneLariat::Clients::Sns.new }
        dependency(:on_sending_error) { CycloneLariat::Outbox.config.on_sending_error }

        def call
          messages_repo.each_with_error do |message|
            messages_repo.transaction do
              messages_repo.lock(message.uuid)
              sns_client.publish message, fifo: message.fifo?
              messages_repo.delete(message.uuid)
            rescue StandardError => e
              messages_repo.update_error(message.uuid, e.message)
              on_sending_error&.call(message, e)
            end
          end
        end
      end
    end
  end
end
