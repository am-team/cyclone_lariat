# frozen_string_literal: true

require_relative 'messages_repo'
require 'luna_park/errors'
require 'json'

module CycloneLariat
  class Middleware
    def initialize(dataset: nil, errors_notifier: nil, message_notifier: nil, repo: MessagesRepo)
      events_dataset    = dataset || CycloneLariat.events_dataset
      @events_repo      = repo.new(events_dataset) if events_dataset
      @message_notifier = message_notifier
      @errors_notifier  = errors_notifier
    end

    def call(_worker_instance, queue, _sqs_msg, body, &block)
      msg = receive_message!(body)

      message_notifier&.info 'Receive message', message: msg, queue: queue
      return if msg.is_a? String

      catch_standard_error(queue, msg) do
        event = Event.wrap(msg)

        store_in_dataset(event) do
          catch_business_error(event, &block)
        end
      end
    end

    private

    attr_reader :errors_notifier, :message_notifier, :events_repo

    def receive_message!(body)
      body[:Message] ? JSON.parse(body[:Message], symbolize_names: true) : body
    rescue JSON::ParserError => e
      errors_notifier&.error(e, message: body[:Message])
      body[:Message]
    end

    def store_in_dataset(event)
      return yield if events_repo.nil?

      existed = events_repo.find(uuid: event.uuid)
      return true if existed&.processed?

      events_repo.create(event) unless existed
      yield
      events_repo.processed! uuid: event.uuid, error: event.client_error
    end

    def catch_business_error(event)
      yield
    rescue LunaPark::Errors::Business => e
      errors_notifier&.error(e, event: event)
      event.client_error = e
    end

    def catch_standard_error(queue, msg)
      yield
    rescue Exception => e
      errors_notifier&.error(e, queue: queue, message: msg)
      raise e
    end
  end
end
