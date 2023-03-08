# frozen_string_literal: true

module CycloneLariat
  module Plugins
    class Outbox
      module Extensions
        module Sequel
          def transaction(**options, &block)
            return super unless opts.delete(:with_outbox)

            sns_client = opts.delete(:sns_client) || default_sns_client

            ActiveRecord::Base.transaction(opts) do
              block.call(outbox)
              outbox.each { |message| message.uid = outbox_messages_repo.create(message) }
            end

            outbox.each do |message|
              sns_client.publish message
              repo.delete(message.uid)
            rescue StandardError => e
              next
            end
          end

          def outbox_messages_repo
            @outbox_messages_repo ||= Repo::OutboxMessages.new(config)
          end

          def default_sns_client
            @default_sns_client ||= CycloneLariat::Clients::Sns.new(config)
          end
        end
      end
    end
  end
end
