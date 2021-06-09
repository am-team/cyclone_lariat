# frozen_string_literal: true

require_relative '../../lib/cyclone_lariat/sqs_client'
require 'timecop'

RSpec.describe CycloneLariat::SqsClient do
  let(:client) do
    described_class.new(key: 'key', secret_key: 'secret_key', region: 'region', publisher: 'sample_app')
  end

  describe '#publish' do
    let(:existed_queue)         { double(queue_url: 'prod-event-queue-sample_app-create_note') }
    let(:aws_sqs_client)        { instance_double(Aws::SQS::Client, get_queue_url: existed_queue) }
    let(:aws_sqs_client_class)  { class_double(Aws::SQS::Client, new: aws_sqs_client) }
    let(:aws_credentials_class) { class_double(Aws::Credentials, new: nil) }
    let(:event)                 { client.event('create_note', data: { text: 'Test note' }) }

    before do
      client.dependencies = {
        aws_client_class: -> { aws_sqs_client_class },
        aws_credentials_class: -> { aws_credentials_class }
      }
    end

    context 'when topic title is not defined' do
      subject(:publish_event) { client.publish event, dest: 'destination' }

      context 'when topic exists' do
        let(:message) do
          {
            uuid: event.uuid,
            publisher: 'sample_app',
            type: 'event_create_note',
            version: 1,
            data: { text: 'Test note' }
          }.to_json
        end

        it 'should be sent to topic expected message' do
          expect(aws_sqs_client).to receive(:send_message).with(
            message_body: message,
            queue_url: 'prod-event-queue-sample_app-create_note'
          )
          publish_event
        end
      end

      context 'when topic does not exists' do
        let(:aws_sqs_client) { instance_double(Aws::SQS::Client, list_queues: []) }

        before do
          allow(aws_sqs_client).to receive(:get_queue_url).and_raise(Aws::SQS::Errors::NonExistentQueue.new([], []))
        end

        it 'should be sent to topic expected message' do
          expect { publish_event }.to raise_error CycloneLariat::Errors::TopicNotFound
        end
      end
    end

    context 'when topic title is defined' do
      subject(:publish_event) { client.publish event, topic: 'defined_topic', dest: 'destination' }

      context 'when topic exists' do
        let(:message) do
          {
            uuid: event.uuid,
            publisher: 'sample_app',
            type: 'event_create_note',
            version: 1,
            data: { text: 'Test note' }
          }.to_json
        end

        it 'should be sent to topic expected message' do
          expect(aws_sqs_client).to receive(:send_message).with(
            queue_url: 'prod-event-queue-sample_app-create_note',
            message_body: message
          )
          publish_event
        end
      end
    end
  end
end
