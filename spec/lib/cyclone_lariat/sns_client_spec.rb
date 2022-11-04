# frozen_string_literal: true
require_relative '../../../lib/cyclone_lariat/configure'
require_relative '../../../lib/cyclone_lariat/sns_client'
require_relative '../../../lib/cyclone_lariat/sqs_client'
require 'timecop'

RSpec.describe CycloneLariat::SnsClient do
  let(:client) do
    described_class.new(
      key: 'key',
      secret_key: 'secret_key',
      region: 'region',
      publisher: 'sample_app',
      instance: :test,
      account_id: 42
    )
  end

  let(:aws_sns_client) { instance_double(Aws::SNS::Client, get_topic_attributes: double) }
  let(:aws_sns_client_class) { class_double(Aws::SNS::Client, new: aws_sns_client) }
  let(:aws_credentials_class) { class_double(Aws::Credentials, new: nil) }

  before do
    client.dependencies = {
      aws_client_class: -> { aws_sns_client_class },
      aws_credentials_class: -> { aws_credentials_class }
    }
  end

  describe '#custom_topic' do
    subject(:custom_topic) { client.custom_topic('custom_name') }

    it { is_expected.to be_a CycloneLariat::Topic }

    it 'should be custom topic' do
      expect(custom_topic.custom?).to eq true
    end

    it 'should create expected topic' do
      expect(custom_topic.name).to eq 'custom_name'
      expect(custom_topic.arn).to eq 'arn:aws:sns:region:42:custom_name'
    end
  end

  describe '#topic' do
    context 'when fifo disabled' do
      subject(:standard_topic) { client.topic('notes_was_added', fifo: false) }

      it { is_expected.to be_a CycloneLariat::Topic }

      it 'should be standard topic' do
        expect(standard_topic.standard?).to eq true
      end

      it 'should be not fifo topic' do
        expect(standard_topic.fifo).to eq false
      end

      it 'should has expected arn' do
        expect(standard_topic.arn).to eq 'arn:aws:sns:region:42:test-event-fanout-sample_app-notes_was_added'
      end
    end

    context 'when fifo enabled' do
      subject(:standard_topic) { client.topic('notes_was_added', fifo: true) }

      it { is_expected.to be_a CycloneLariat::Topic }

      it 'should be standard topic' do
        expect(standard_topic.standard?).to eq true
      end

      it 'should be fifo topic' do
        expect(standard_topic.fifo).to eq true
      end

      it 'should has expected arn' do
        expect(standard_topic.arn).to eq 'arn:aws:sns:region:42:test-event-fanout-sample_app-notes_was_added.fifo'
      end
    end

    context 'when kind is command' do
      subject(:standard_topic) { client.topic('notes_was_added', fifo: true, kind: :command) }

      it { is_expected.to be_a CycloneLariat::Topic }

      it 'should be standard topic' do
        expect(standard_topic.standard?).to eq true
      end

      it 'should be command topic' do
        expect(standard_topic.kind).to eq :command
      end

      it 'should create expected topic' do
        expect(standard_topic.arn).to eq 'arn:aws:sns:region:42:test-command-fanout-sample_app-notes_was_added.fifo'
      end
    end
  end

  describe '#exists?' do
    subject(:exists?) { client.exists? client.topic('test-event-fanout-sample_app-create_note', fifo: false) }

    context 'when topic already exists' do
      it { is_expected.to be true }
    end

    context 'when topic does not exists' do
      before { allow(aws_sns_client).to receive(:get_topic_attributes).and_raise(Aws::SNS::Errors::NotFound.new('context', 'message')) }

      it { is_expected.to be false }
    end
  end

  describe '#create' do
    subject(:create_topic) { client.create client.topic('create_note', fifo: true) }

    context 'when topic already exists' do
      it 'should raise error' do
        expect { create_topic }.to raise_error CycloneLariat::Errors::TopicAlreadyExists
      end
    end

    context 'when topic does not exists and fifo enabled' do
      before { allow(aws_sns_client).to receive(:get_topic_attributes).and_raise(Aws::SNS::Errors::NotFound.new('context', 'message')) }

      it 'should create new one FIFO topic' do
        expect(aws_sns_client).to receive(:create_topic).with(
          name: 'test-event-fanout-sample_app-create_note.fifo',
          attributes: { 'FifoTopic' => 'true' },

        )

        create_topic
      end
    end

    context 'when topic does not exists and fifo disabled' do
      subject(:create_topic) { client.create client.topic('create_note', fifo: false) }
      before { allow(aws_sns_client).to receive(:get_topic_attributes).and_raise(Aws::SNS::Errors::NotFound.new('context', 'message')) }

      it 'should create new one non-FIFO topic' do
        expect(aws_sns_client).to receive(:create_topic).with(
          name: 'test-event-fanout-sample_app-create_note',
          attributes: {},
          tags: [
            { key: 'instance', value: 'test' },
            { key: 'kind', value: 'event' },
            { key: 'publisher', value: 'sample_app' },
            { key: 'type', value: 'create_note' },
            { key: 'fifo', value: 'false' }
          ]
        )

        create_topic
      end
    end
  end

  describe '#delete' do
    subject(:delete_topic) { client.delete client.topic('create_note', fifo: true) }

    context 'when topic does not exists' do
      before { allow(aws_sns_client).to receive(:get_topic_attributes).and_raise(Aws::SNS::Errors::NotFound.new('context', 'message')) }

      it 'should raise error' do
        expect { delete_topic }.to raise_error CycloneLariat::Errors::TopicDoesNotExists
      end
    end

    context 'when topic already exists' do
      it 'should delete new one topic' do
        expect(aws_sns_client).to receive(:delete_topic).with(
          topic_arn: 'arn:aws:sns:region:42:test-event-fanout-sample_app-create_note.fifo'
        )

        delete_topic
      end
    end
  end

  describe '#publish' do
    let(:event) { client.event('create_note', data: { text: 'Test note' }) }
    let(:event_sent_at) { Time.now }

    context 'when topic title is not defined' do
      subject(:publish_event) { client.publish event, fifo: true }

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
          expect(aws_sns_client).to receive(:publish).with(
            message: message,
            topic_arn: 'arn:aws:sns:region:42:test-event-fanout-sample_app-create_note.fifo'
          )
          publish_event
        end
      end

      context 'when topic does not exists' do
        before { allow(aws_sns_client).to receive(:publish).and_raise(Aws::SNS::Errors::NotFound.new('context', 'message')) }

        it 'should be sent to topic expected message' do
          expect { publish_event }.to raise_error Aws::SNS::Errors::NotFound
        end
      end
    end

    context 'when topic title is defined' do
      subject(:publish_event) { client.publish event, topic: 'defined_topic', fifo: false }
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
          expect(aws_sns_client).to receive(:publish).with(
            message: message,
            topic_arn: 'arn:aws:sns:region:42:defined_topic'
          )
          publish_event
        end
      end

      context 'when topic does not exists' do
        before { allow(aws_sns_client).to receive(:publish).and_raise(Aws::SNS::Errors::NotFound.new('context', 'message')) }

        it 'should be sent to topic expected message' do
          expect { publish_event }.to raise_error Aws::SNS::Errors::NotFound
        end
      end
    end
  end

  describe '#subscribe' do
    let(:topic) { client.topic(:note_added, fifo: true) }
    let(:sqs_client) do
      CycloneLariat::SqsClient.new(
        key: 'key',
        secret_key: 'secret_key',
        region: 'region',
        publisher: 'sample_app',
        instance: :test,
        account_id: 42
      )
    end

    let(:queue) { sqs_client.queue(:note_added, fifo: true) }

    subject(:subscribe) { client.subscribe(topic: topic, endpoint: queue) }

    context 'when subscription already exists' do

      before do
        allow(aws_sns_client).to receive(:list_subscriptions_by_topic).with(topic_arn: topic.arn).and_return(
          {
            subscriptions: [instance_double(Aws::SNS::Types::Subscription, endpoint: queue.arn, subscription_arn: 'subscription_arn')],
            next_token: nil
          }
        )
      end

      it 'should raise error' do
        # expect(subscribe).to eq true
        expect { subscribe }.to raise_error CycloneLariat::Errors::SubscriptionAlreadyExists
      end
    end


  end
end
