# frozen_string_literal: true

require_relative '../../lib/cyclone_lariat/sns_client'
require 'timecop'

RSpec.describe CycloneLariat::SnsClient do
  let(:client) do
    described_class.new(key: 'key', secret_key: 'secret_key', region: 'region', publisher: 'sample_app')
  end

  describe '#publish' do
    let(:existed_topic)         { double(topic_arn: 'prod-event-fanout-sample_app-create_note') }
    let(:aws_sns_client)        { instance_double(Aws::SNS::Client, list_topics: double(topics: [existed_topic])) }
    let(:aws_sns_client_class)  { class_double(Aws::SNS::Client, new: aws_sns_client) }
    let(:aws_credentials_class) { class_double(Aws::Credentials, new: nil) }
    let(:event)                 { client.event('create_note', data: { text: 'Test note' }) }

    before do
      client.dependencies = {
        aws_client_class: -> { aws_sns_client_class },
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
      subject(:publish_event) { client.publish event, topic: 'defined_topic' }

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
