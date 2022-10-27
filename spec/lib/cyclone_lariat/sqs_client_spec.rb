# frozen_string_literal: true

require_relative '../../../lib/cyclone_lariat/sqs_client'
require 'timecop'

RSpec.describe CycloneLariat::SqsClient do
  let(:client) do
    described_class.new(key: 'key', secret_key: 'secret_key', region: 'region', publisher: 'sample_app', instance: :test)
  end

  let(:aws_sqs_client)        { instance_double(Aws::SQS::Client, get_queue_url: double(queue_url: 'test-event-queue-sample_app-create_note')) }
  let(:aws_sqs_client_class)  { class_double(Aws::SQS::Client, new: aws_sqs_client) }
  let(:aws_credentials_class) { class_double(Aws::Credentials, new: nil) }

  let(:event_sent_at)         { Time.now }

  before do
    client.dependencies = {
      aws_client_class: -> { aws_sqs_client_class },
      aws_credentials_class: -> { aws_credentials_class }
    }

    Timecop.freeze event_sent_at
  end

  describe '#exists?' do
    subject(:exists?) { client.exists? :create_note }

    context 'when topic already exists' do
      it { is_expected.to be true }
    end

    context 'when topic does not exists' do
      before do
        error = Aws::SQS::Errors.error_class('NonExistentQueue').new('message', 'context')
        allow(aws_sqs_client).to receive(:get_queue_url).and_raise error
      end

      it { is_expected.to be false }
    end
  end

  describe 'create_topic!' do
    subject(:create_topic!) { client.create_topic! 'test-event-queue-sample_app-create_note', fifo: true }

    context 'when topic already exists' do
      it 'should raise error' do
        expect { create_topic! }.to raise_error CycloneLariat::Errors::TopicAlreadyExists
      end
    end

    context 'when topic does not exists and create FIFO' do
      before do
        error = Aws::SQS::Errors.error_class('NonExistentQueue').new('message', 'context')
        allow(aws_sqs_client).to receive(:get_queue_url).and_raise error
      end

      it 'should create new one FIFO topic' do
        expect(aws_sqs_client).to receive(:create_queue).with(
          queue_name: 'test-event-queue-sample_app-create_note',
          attributes: { 'FifoQueue' => true }
        )

        create_topic!
      end
    end

    context 'when topic does not exists and create non-FIFO' do
      subject(:create_topic!) { client.create_topic! 'test-event-queue-sample_app-create_note', fifo: false }

      before do
        error = Aws::SQS::Errors.error_class('NonExistentQueue').new('message', 'context')
        allow(aws_sqs_client).to receive(:get_queue_url).and_raise error
      end

      it 'should create new one FIFO topic' do
        expect(aws_sqs_client).to receive(:create_queue).with(
          queue_name: 'test-event-queue-sample_app-create_note',
          attributes: {}
        )

        create_topic!
      end
    end
  end

  describe 'create_event_topic!' do
    before do
      error = Aws::SQS::Errors.error_class('NonExistentQueue').new('message', 'context')
      allow(aws_sqs_client).to receive(:get_queue_url).and_raise error
    end

    context 'type & destination is defined' do
      subject(:create_event_topic!) { client.create_event_topic! type: :new_user, dest: :notify_service, fifo: true }

      it 'should create topic <instance>-event-queue-<application>-<event_type>-<destination_service>' do
        expect(aws_sqs_client).to receive(:create_queue).with(
          queue_name: 'test-event-queue-sample_app-new_user-notify_service',
          attributes: { 'FifoQueue' => true }
        )

        create_event_topic!
      end
    end

    context 'type is defined, dest is undefined' do
      subject(:create_event_topic!) { client.create_event_topic! type: :new_user, fifo: true }

      it 'should create topic <instance>-event-queue-<application>-<event_type>' do
        expect(aws_sqs_client).to receive(:create_queue).with(
          queue_name: 'test-event-queue-sample_app-new_user',
          attributes: { 'FifoQueue' => true }
        )

        create_event_topic!
      end
    end

    context 'type is undefined, dest is defined' do
      subject(:create_event_topic!) { client.create_event_topic! fifo: true, dest: :notify_service }

      it 'should create topic <instance>-event-queue-<application>-all-<destination_service>' do
        expect(aws_sqs_client).to receive(:create_queue).with(
          queue_name: 'test-event-queue-sample_app-all-notify_service',
          attributes: { 'FifoQueue' => true }
        )

        create_event_topic!
      end
    end
  end

  describe 'create_command_topic!' do
    before do
      error = Aws::SQS::Errors.error_class('NonExistentQueue').new('message', 'context')
      allow(aws_sqs_client).to receive(:get_queue_url).and_raise error
    end

    context 'type & destination is defined' do
      subject(:create_command_topic!) { client.create_command_topic! type: :create_user, dest: :notify_service, fifo: true }

      it 'should create topic <instance>-event-queue-<application>-<event_type>-<destination_service>' do
        expect(aws_sqs_client).to receive(:create_queue).with(
          queue_name: 'test-command-queue-sample_app-create_user-notify_service',
          attributes: { 'FifoQueue' => true }
        )

        create_command_topic!
      end
    end

    context 'type is defined, dest is undefined' do
      subject(:create_command_topic!) { client.create_command_topic! type: :create_user, fifo: true }

      it 'should create topic <instance>-command-queue-<application>-<command_type>' do
        expect(aws_sqs_client).to receive(:create_queue).with(
          queue_name: 'test-command-queue-sample_app-create_user',
          attributes: { 'FifoQueue' => true }
        )

        create_command_topic!
      end
    end

    context 'type is undefined, dest is defined' do
      subject(:create_command_topic!) { client.create_command_topic! fifo: true, dest: :notify_service }

      it 'should create topic <instance>-command-queue-<application>-all-<destination_service>' do
        expect(aws_sqs_client).to receive(:create_queue).with(
          queue_name: 'test-command-queue-sample_app-all-notify_service',
          attributes: { 'FifoQueue' => true }
        )

        create_command_topic!
      end
    end
  end

  describe 'delete_topic!' do
    subject(:delete_topic!) { client.delete_topic! 'test-event-queue-sample_app-new_user' }

    context 'when topic does not exists' do
      before do
        error = Aws::SQS::Errors.error_class('NonExistentQueue').new('message', 'context')
        allow(aws_sqs_client).to receive(:get_queue_url).and_raise error
      end

      it 'should raise error' do
        expect { delete_topic! }.to raise_error CycloneLariat::Errors::TopicDoesNotExists
      end
    end

    context 'when topic already exists' do
      it 'should delete new one topic' do
        expect(aws_sqs_client).to receive(:delete_queue).with(
          queue_url: 'test-event-queue-sample_app-create_note'
        )

        delete_topic!
      end
    end
  end

  describe '#publish' do
    let(:event) { client.event('create_note', data: { text: 'Test note' }) }

    context 'when topic title is not defined' do
      subject(:publish_event) { client.publish event, dest: 'destination' }

      context 'when topic exists' do
        let(:message) do
          {
            uuid: event.uuid,
            publisher: 'sample_app',
            type: 'event_create_note',
            version: 1,
            data: { text: 'Test note' },
            sent_at: event_sent_at
          }.to_json
        end

        it 'should be sent to topic expected message' do
          expect(aws_sqs_client).to receive(:send_message).with(
            message_body: message,
            queue_url: 'test-event-queue-sample_app-create_note'
          )
          publish_event
        end
      end

      context 'when topic does not exists' do
        before do
          allow(aws_sqs_client).to receive(:get_queue_url).and_raise(Aws::SQS::Errors::NonExistentQueue.new([], []))
        end

        it 'should be sent to topic expected message' do
          expect { publish_event }.to raise_error Aws::SQS::Errors::NonExistentQueue
        end
      end
    end

    context 'when topic title is defined' do
      subject(:publish_event) { client.publish event, topic: 'defined_topic', dest: 'destination' }
      before { Timecop.freeze event_sent_at }

      context 'when topic exists' do
        let(:message) do
          {
            uuid: event.uuid,
            publisher: 'sample_app',
            type: 'event_create_note',
            version: 1,
            data: { text: 'Test note' },
            sent_at: event_sent_at

          }.to_json
        end

        it 'should be sent to topic expected message' do
          expect(aws_sqs_client).to receive(:send_message).with(
            queue_url: 'test-event-queue-sample_app-create_note',
            message_body: message
          )
          publish_event
        end
      end
    end
  end
end
