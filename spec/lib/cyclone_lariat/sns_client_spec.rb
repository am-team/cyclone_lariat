# frozen_string_literal: true

require_relative '../../../lib/cyclone_lariat/configure'
# require_relative '../../config/initializers/cyclone_lariat'
require_relative '../../../lib/cyclone_lariat/sns_client'
require 'timecop'

RSpec.describe CycloneLariat::SnsClient do
  let(:client) do
    described_class.new(key: 'key', secret_key: 'secret_key', region: 'region', publisher: 'sample_app', instance: :test, client_id: 42)
  end

  describe '#publish' do
    let(:aws_sns_client)        { instance_double(Aws::SNS::Client) }
    let(:aws_sns_client_class)  { class_double(Aws::SNS::Client, new: aws_sns_client) }
    let(:aws_credentials_class) { class_double(Aws::Credentials, new: nil) }
    let(:event) { client.event('create_note', data: { text: 'Test note' }) }
    let(:event_sent_at) { Time.now }

    before do
      client.dependencies = {
        aws_client_class: -> { aws_sns_client_class },
        aws_credentials_class: -> { aws_credentials_class }
      }

      Timecop.freeze event_sent_at
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
