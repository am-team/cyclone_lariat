# frozen_string_literal: true

require 'cyclone_lariat/clients/sns'
require 'cyclone_lariat/plugins/outbox/repo/messages'

module CycloneLariat
  module Outbox
    module Extensions
      module SequelTransaction
        def transaction(opts = {}, &block)
          opts = Sequel::OPTS.dup.merge(opts)
          return super unless opts.delete(:with_outbox)

          outbox = []
          block_result = nil
          messages_repo = CycloneLariat::Outbox::Repo::Messages.new

          super(opts) do |conn|
            block_result = block.call(outbox, conn)
            outbox.each { |message| message.uuid = messages_repo.create(message) }
          end

          published_message_uuids = send_outbox_messages(outbox, messages_repo)
          messages_repo.delete(published_message_uuids)

          block_result
        end

        private

        def send_outbox_messages(outbox, messages_repo)
          sns_client = CycloneLariat::Clients::Sns.new
          on_error_callback = CycloneLariat::Outbox.config.on_sending_error

          outbox.each_with_object([]) do |message, published_message_uuids|
            begin
              sns_client.publish message, fifo: message.fifo?
              published_message_uuids << message.uuid
            rescue StandardError => e
              messages_repo.update_error(message.uuid, e.message)
              on_error_callback.call(message, e) if on_error_callback
              next
            end
          end
        end
      end
    end
  end
end
