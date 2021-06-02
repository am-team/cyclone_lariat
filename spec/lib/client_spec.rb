# frozen_string_literal: true

require_relative '../../lib/cyclone_lariat/client'
require 'timecop'

RSpec.describe CycloneLariat::Client do
  let(:client) do
    described_class.new(key: 'key', secret_key: 'secret_key', region: 'region', publisher: 'sample_app')
  end

  describe '.version' do
    after { described_class.version 1 }

    it 'sets dependency' do
      expect { described_class.version(42) }.to change { described_class.version }.from(1).to 42
    end
  end

  describe '.publisher' do
    subject(:publisher) { described_class.publisher }

    context 'when it does not defined' do
      it 'should be defined' do
        expect { publisher }.to raise_error RuntimeError, 'You should define publisher'
      end
    end

    context 'when it does defined' do
      before { described_class.publisher 'you_app' }

      it 'should be defined' do
        expect(publisher).to eq 'you_app'
      end
    end
  end

  describe '#event' do
    context 'version is not defined' do
      subject(:event) { client.event('create_user', data: { mail: 'john.doe@mail.ru' }, uuid: uuid) }
      let(:event_sent_at) { Time.local(2021) }
      let(:uuid) { SecureRandom.uuid }

      before { Timecop.freeze event_sent_at }
      after  { Timecop.return }

      it 'should build expected event' do
        is_expected.to eq CycloneLariat::Event.new(
          uuid: uuid,
          type: 'create_user',
          sent_at: event_sent_at,
          version: 1,
          publisher: 'sample_app',
          data: { mail: 'john.doe@mail.ru' }
        )
      end
    end

    context 'version is defined' do
      subject(:event) { client.event('create_user', data: { mail: 'john.doe@mail.ru' }, uuid: uuid, version: 12) }
      let(:event_sent_at) { Time.local(2021) }
      let(:uuid) { SecureRandom.uuid }

      before { Timecop.freeze event_sent_at }
      after  { Timecop.return }

      it 'should build expected event with defined version' do
        is_expected.to eq CycloneLariat::Event.new(
          uuid: uuid,
          type: 'create_user',
          sent_at: event_sent_at,
          version: 12,
          publisher: 'sample_app',
          data: { mail: 'john.doe@mail.ru' }
        )
      end
    end
  end

  describe '#publish' do
    let(:existed_topic)         { double(topic_arn: 'prod-event-fanout-sample_app-create_note') }
    let(:aws_sns_client)        { instance_double(Aws::SNS::Client, list_topics: double(topics: [existed_topic])) }
    let(:aws_sns_client_class)  { class_double(Aws::SNS::Client, new: aws_sns_client) }
    let(:aws_credentials_class) { class_double(Aws::Credentials, new: nil) }
    let(:event)                 { client.event('create_note', data: { text: 'Test note' }) }

    before do
      client.dependencies = {
        aws_sns_client_class: -> { aws_sns_client_class },
        aws_credentials_class: -> { aws_credentials_class }
      }
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
            data: { text: 'Test note' }
          }.to_json
        end

        it 'should be sent to topic expected message' do
          expect(aws_sns_client).to receive(:publish).with(
            message: message,
            topic_arn: 'prod-event-fanout-sample_app-create_note'
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
      subject(:publish_event) { client.publish event, to: 'defined_topic' }

      context 'when topic exists' do
        let(:existed_topic) { double(topic_arn: 'defined_topic') }

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
