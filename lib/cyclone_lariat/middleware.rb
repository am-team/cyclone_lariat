# frozen_string_literal: true

require_relative 'messages_repo'
require 'luna_park/errors'
require 'json'

module CycloneLariat
  class Middleware
    def initialize(dataset: nil, errors_notifier: nil, message_notifier: nil, repo: MessagesRepo)
      @events_repo      = repo.new(dataset) if dataset
      @message_notifier = message_notifier
      @errors_notifier  = errors_notifier
    end

    def call(_worker_instance, queue, _sqs_msg, body, &block)
      msg = receive_message(body)

      message_notifier&.info 'Receive message', message: msg, queue: queue

      catch_standard_error(queue, msg) do
        event = Event.wrap(msg)

        catch_business_error(event) do
          store_in_dataset(event, &block)
        end
      end
    end

    private

    attr_reader :errors_notifier, :message_notifier, :events_repo

    def receive_message(body)
      body[:Message] ? JSON.parse(body[:Message], symbolize_names: true ) : body
    end

    def store_in_dataset(event)
      return yield if events_repo.nil?
      return true  if events_repo.exists?(uuid: event.uuid)

      events_repo.create(event)
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
    rescue StandardError => e
      errors_notifier&.error(e, queue: queue, message: msg)
      raise e
    end
  end
end
