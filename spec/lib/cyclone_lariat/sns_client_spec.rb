# frozen_string_literal: true

require_relative '../../../lib/cyclone_lariat/sns_client'
require 'timecop'

RSpec.describe CycloneLariat::SnsClient do
  let(:client) do
    described_class.new(key: 'key', secret_key: 'secret_key', region: 'region', publisher: 'sample_app', instance: :test)
  end

  describe '#create_topic' do
    subject(:create_topic) { client.create_topic 'test-event-fanout-sample_app-create_note' }

    let(:aws_sns_client) do
      instance_double(
        Aws::SNS::Client,
        list_topics: double(topics: [], next_token: nil)
      )
    end

    let(:aws_sns_client_class) { class_double(Aws::SNS::Client, new: aws_sns_client) }
    let(:aws_credentials_class) { class_double(Aws::Credentials, new: nil) }

    before do
      client.dependencies = {
        aws_client_class: -> { aws_sns_client_class },
        aws_credentials_class: -> { aws_credentials_class }
      }

      CycloneLariat::ListTopicsStore.instance.clear_store!
    end

    context 'when topic already exists' do
      let(:existed_topic) do
        double(topic_arn: 'test-event-fanout-sample_app-create_note')
      end

      let(:aws_sns_client) do
        instance_double(
          Aws::SNS::Client,
          list_topics: double(topics: [existed_topic], next_token: nil)
        )
      end

      it 'should create new one topic' do
        expect(aws_sns_client).to receive(:create_topic).with(
          name: 'test-event-fanout-sample_app-create_note'
        )
        create_topic
      end
    end

    context 'when topic does not exists' do
      let(:existed_topic) do
        double(topic_arn: 'test-event-fanout-sample_app-create_note')
      end

      it 'should be sent to topic expected message' do
        expect { create_topic }.to raise_error CycloneLariat::Errors::TopicAlreadyExists
      end
    end
  end

  describe '#publish' do
    let(:existed_topic) do
      double(topic_arn: 'test-event-fanout-sample_app-create_note')
    end

    let(:aws_sns_client) do
      instance_double(
        Aws::SNS::Client,
        list_topics: double(topics: [existed_topic], next_token: nil)
      )
    end
    let(:aws_sns_client_class) { class_double(Aws::SNS::Client, new: aws_sns_client) }
    let(:aws_credentials_class) { class_double(Aws::Credentials, new: nil) }
    let(:event) { client.event('create_note', data: { text: 'Test note' }) }
    let(:event_sent_at) { Time.now }

    before do
      client.dependencies = {
        aws_client_class: -> { aws_sns_client_class },
        aws_credentials_class: -> { aws_credentials_class }
      }

      Timecop.freeze event_sent_at
      CycloneLariat::ListTopicsStore.instance.clear_store!
    end

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
            topic_arn: 'test-event-fanout-sample_app-create_note'
          )
          publish_event
        end
      end

      context 'when topic does not exists' do
        let(:existed_topic) { double(topic_arn: 'foobar') }

        it 'should be sent to topic expected message' do
          expect { publish_event }.to raise_error CycloneLariat::Errors::TopicNotFound
        end
      end
    end

    context 'when topic title is defined' do
      subject(:publish_event) { client.publish event, topic: 'defined_topic' }
      before { Timecop.freeze event_sent_at }

      context 'when topic exists' do
        let(:existed_topic) { double(topic_arn: 'defined_topic') }

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
            topic_arn: 'defined_topic'
          )
          publish_event
        end
      end

      context 'when topic does not exists' do
        let(:existed_topic) { double(topic_arn: 'foobar') }

        it 'should be sent to topic expected message' do
          expect { publish_event }.to raise_error CycloneLariat::Errors::TopicNotFound
        end
      end
    end
  end
end
