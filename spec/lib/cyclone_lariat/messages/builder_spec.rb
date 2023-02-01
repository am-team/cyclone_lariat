# frozen_string_literal: true

require 'cyclone_lariat/messages/builder'

RSpec.describe CycloneLariat::Messages::Builder do
  let(:builder) { described_class.new(raw_message: raw_message) }
  let(:raw_message_v1) do
    {
      data: {
        xxx: 'yyy'
      },
      publisher: 'some_service',
      sent_at: Time.now.iso8601,
      type: message_type,
      uuid: SecureRandom.uuid,
      version: message_version
    }
  end
  let(:raw_message_v2) do
    {
      data: {
        xxx: 'yyy'
      },
      object: {
        type: 'ddd',
        uuid: SecureRandom.uuid
      },
      publisher: 'some_service',
      sent_at: Time.now.iso8601,
      subject: {
        type: 'zzz',
        uuid: SecureRandom.uuid
      },
      type: message_type,
      uuid: SecureRandom.uuid,
      version: message_version
    }
  end

  describe '#call' do
    subject(:call) { builder.call }

    context 'event' do
      let(:message_type) { 'event_blabla' }

      context 'v1' do
        context 'when version correct' do
          let(:raw_message) { raw_message_v1 }
          let(:message_version) { '1' }

          it do
            is_expected.to be_a CycloneLariat::Messages::V1::Event
          end
        end

        context 'when version unknown' do
          let(:raw_message) { raw_message_v1 }
          let(:message_version) { '12' }

          it do
            expect { call }.to raise_error(ArgumentError, "Unknown event message version #{message_version}")
          end
        end
      end

      context 'v2' do
        context 'when version correct' do
          let(:raw_message) { raw_message_v2 }
          let(:message_version) { '2' }

          it do
            is_expected.to be_a CycloneLariat::Messages::V2::Event
          end
        end

        context 'when version unknown' do
          let(:raw_message) { raw_message_v2 }
          let(:message_version) { '12' }

          it do
            expect { call }.to raise_error(ArgumentError, "Unknown event message version #{message_version}")
          end
        end
      end
    end

    context 'command' do
      let(:message_type) { 'command_blabla' }

      context 'v1' do
        context 'when version correct' do
          let(:raw_message) { raw_message_v1 }
          let(:message_version) { '1' }

          it do
            is_expected.to be_a CycloneLariat::Messages::V1::Command
          end
        end

        context 'when version unknown' do
          let(:raw_message) { raw_message_v1 }
          let(:message_version) { '12' }

          it do
            expect { call }.to raise_error(ArgumentError, "Unknown command message version #{message_version}")
          end
        end
      end

      context 'v2' do
        context 'when version correct' do
          let(:raw_message) { raw_message_v2 }
          let(:message_version) { '2' }

          it do
            is_expected.to be_a CycloneLariat::Messages::V2::Command
          end
        end

        context 'when version unknown' do
          let(:raw_message) { raw_message_v2 }
          let(:message_version) { '12' }

          it do
            expect { call }.to raise_error(ArgumentError, "Unknown command message version #{message_version}")
          end
        end
      end
    end

    context 'unknown message type' do
      context 'when parseable' do
        let(:message_type) { 'asaa_blabla' }
        let(:message_version) { '12' }
        let(:raw_message) { raw_message_v2 }

        it do
          expect { call }.to raise_error(ArgumentError, "Unknown message type #{message_type.split('_').first}")
        end
      end

      context 'when strange format' do
        let(:message_type) { 'blabla-3211' }
        let(:message_version) { '12' }
        let(:raw_message) { raw_message_v2 }

        it do
          expect { call }.to raise_error(ArgumentError, "Unknown message type #{message_type.split('_').first}")
        end
      end
    end
  end
end
