# frozen_string_literal: true

require 'cyclone_lariat/clients/sns'
require 'cyclone_lariat/plugins/outbox/repo/messages'

module CycloneLariat
  module Outbox
    module Extensions
      module ActiveRecordTransaction
        def transaction(opts = {}, &block)
          return super unless opts.delete(:with_outbox)

          outbox = []
          block_result = nil
          super(opts) do
            block_result = block.call(outbox)
            outbox.each { |message| message.uuid = outbox_messages_repo.create(message) }
          end

          sended_message_uuids = []
          outbox.each do |message|
            begin
              sns_client.publish message, fifo: message.fifo?
              sended_message_uuids << message.uuid
            rescue StandardError => e
              outbox_messages_repo.update_error(message.uuid, e.message)
              next
            end
          end

          outbox_messages_repo.delete(sended_message_uuids)
          block_result
        end

        def outbox_messages_repo
          @outbox_messages_repo ||= CycloneLariat::Outbox::Repo::Messages.new
        end

        def sns_client
          @sns_client ||= CycloneLariat::Clients::Sns.new
        end
      end
    end
  end
end
