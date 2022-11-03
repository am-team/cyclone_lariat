# frozen_string_literal: true


require_relative '../../../lib/cyclone_lariat/configure'
require_relative '../../../lib/cyclone_lariat/sns_client'
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

  describe '#exists?' do
    subject(:exists?) { client.exists? 'test-event-fanout-sample_app-create_note' }

    context 'when topic already exists' do
      it { is_expected.to be true }
    end

    context 'when topic does not exists' do
      before { allow(aws_sns_client).to receive(:get_topic_attributes).and_raise(Aws::SNS::Errors::NotFound.new('context', 'message')) }

      it { is_expected.to be false }
    end
  end

  describe '#create_topic!' do
    subject(:create_topic!) { client.create_topic! 'test-event-fanout-sample_app-create_note', fifo: true }

    context 'when topic already exists' do
      it 'should raise error' do
        expect { create_topic! }.to raise_error CycloneLariat::Errors::TopicAlreadyExists
      end
    end

    context 'when topic does not exists and fifo enabled' do
      before { allow(aws_sns_client).to receive(:get_topic_attributes).and_raise(Aws::SNS::Errors::NotFound.new('context', 'message')) }

      it 'should create new one FIFO topic' do
        expect(aws_sns_client).to receive(:create_topic).with(
          name: 'test-event-fanout-sample_app-create_note',
          attributes: { 'FifoTopic' => true }
        )

        create_topic!
      end
    end

    context 'when topic does not exists and fifo disabled' do
      subject(:create_topic!) { client.create_topic! 'test-event-fanout-sample_app-create_note', fifo: false }
      before { allow(aws_sns_client).to receive(:get_topic_attributes).and_raise(Aws::SNS::Errors::NotFound.new('context', 'message')) }

      it 'should create new one non-FIFO topic' do
        expect(aws_sns_client).to receive(:create_topic).with(
          name: 'test-event-fanout-sample_app-create_note',
          attributes: {}
        )

        create_topic!
      end
    end
  end

  describe '#create_event_topic!' do
    subject(:create_topic!) { client.create_event_topic! type: 'create_note', fifo: true }

    before { allow(aws_sns_client).to receive(:get_topic_attributes).and_raise(Aws::SNS::Errors::NotFound.new('context', 'message')) }

    it 'should create new one event topic <instance>-event-<application>-<type>' do
      expect(aws_sns_client).to receive(:create_topic).with(
        name: 'test-event-fanout-sample_app-create_note',
        attributes: { 'FifoTopic' => true }
      )

      create_topic!
    end
  end

  describe '#create_command_topic!' do
    subject(:create_topic!) { client.create_command_topic! type: 'create_note', fifo: true }

    before { allow(aws_sns_client).to receive(:get_topic_attributes).and_raise(Aws::SNS::Errors::NotFound.new('context', 'message')) }

    it 'should create new one command topic <instance>-command-<application>-<type>' do
      expect(aws_sns_client).to receive(:create_topic).with(
        name: 'test-command-fanout-sample_app-create_note',
        attributes: { 'FifoTopic' => true }
      )

      create_topic!
    end
  end

  describe '#delete_topic!' do
    subject(:delete_topic!) { client.delete_topic! 'test-event-fanout-sample_app-create_note' }

    context 'when topic does not exists' do
      before { allow(aws_sns_client).to receive(:get_topic_attributes).and_raise(Aws::SNS::Errors::NotFound.new('context', 'message')) }

      it 'should raise error' do
        expect { delete_topic! }.to raise_error CycloneLariat::Errors::TopicDoesNotExists
      end
    end

    context 'when topic already exists' do
      it 'should delete new one topic' do
        expect(aws_sns_client).to receive(:delete_topic).with(
          topic_arn: 'arn:aws:sns:region:42:test-event-fanout-sample_app-create_note'
        )

        delete_topic!
      end
    end
  end

  describe '#publish' do
    let(:event) { client.event('create_note', data: { text: 'Test note' }) }
    let(:event_sent_at) { Time.now }

    context 'when topic title is not defined' do
      subject(:publish_event) { client.publish event }

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
            topic_arn: 'arn:aws:sns:region:42:test-event-fanout-sample_app-create_note'
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
      subject(:publish_event) { client.publish event, topic: 'defined_topic' }
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
end
