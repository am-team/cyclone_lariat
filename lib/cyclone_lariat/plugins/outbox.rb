# frozen_string_literal: true

require 'cyclone_lariat/core'
require 'cyclone_lariat/clients/sns'
require 'cyclone_lariat/plugins/outbox/configurable'
require 'cyclone_lariat/plugins/outbox/loadable'
require 'cyclone_lariat/plugins/outbox/extensions/active_record_outbox'
require 'cyclone_lariat/plugins/outbox/extensions/sequel_outbox'
require 'cyclone_lariat/plugins/outbox/repo/messages'

module CycloneLariat
  class Outbox
    extend CycloneLariat::Outbox::Configurable
    extend CycloneLariat::Outbox::Loadable
    include LunaPark::Extensions::Injector

    dependency(:sns_client) { CycloneLariat::Clients::Sns.new }
    dependency(:repo)       { CycloneLariat::Outbox::Repo::Messages.new }

    attr_reader :messages

    def initialize
      @messages = []
    end

    def publish
      sent_message_uids = messages.each_with_object([]) do |message, sent_message_uuids|
        sns_client.publish message, fifo: message.fifo?
        sent_message_uuids << message.uuid
      rescue StandardError => e
        repo.update_error(message.uuid, e.message)
        config.on_sending_error&.call(message, e)
        next
      end
      repo.delete(sent_message_uids) unless sent_message_uids.empty?
    end

    def <<(message)
      message.uuid = repo.create(message)
      messages << message
    end

    def push(message)
      self << message
    end

    private

    def config
      self.class.config
    end
  end
end
