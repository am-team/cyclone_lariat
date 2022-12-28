# frozen_string_literal: true

require 'cyclone_lariat/clients/sqs'
require 'timecop'

RSpec.describe CycloneLariat::Clients::Sqs do
  let(:client) do
    described_class.new(
      aws_key: 'key',
      aws_secret_key: 'secret_key',
      aws_region: 'region',
      publisher: 'sample_app',
      instance: :test,
      aws_account_id: 42,
      version: 1
    )
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

  after { Timecop.return }

  describe '#custom_queue' do
    subject(:custom_queue) { client.custom_queue('custom_name') }

    it { is_expected.to be_a CycloneLariat::Resources::Queue }

    it 'should be custom queue' do
      expect(custom_queue.custom?).to eq true
    end

    it 'should create expected queue' do
      expect(custom_queue.name).to eq 'custom_name'
      expect(custom_queue.arn).to eq 'arn:aws:sqs:region:42:custom_name'
    end
  end

  describe '#queue' do
    context 'when fifo disabled' do
      subject(:standard_queue) { client.queue('notes_was_added', fifo: false) }

      it { is_expected.to be_a CycloneLariat::Resources::Queue }

      it 'should be standard queue' do
        expect(standard_queue.standard?).to eq true
      end

      it 'should be not fifo queue' do
        expect(standard_queue.fifo).to eq false
      end

      it 'should has expected arn' do
        expect(standard_queue.arn).to eq 'arn:aws:sqs:region:42:test-event-queue-sample_app-notes_was_added'
      end
    end

    context 'when fifo enabled' do
      subject(:standard_queue) { client.queue('notes_was_added', fifo: true) }

      it { is_expected.to be_a CycloneLariat::Resources::Queue }

      it 'should be standard queue' do
        expect(standard_queue.standard?).to eq true
      end

      it 'should be fifo queue' do
        expect(standard_queue.fifo).to eq true
      end

      it 'should has expected arn' do
        expect(standard_queue.arn).to eq 'arn:aws:sqs:region:42:test-event-queue-sample_app-notes_was_added.fifo'
      end
    end

    context 'when kind is command' do
      subject(:standard_queue) { client.queue('notes_was_added', fifo: true, kind: :command) }

      it { is_expected.to be_a CycloneLariat::Resources::Queue }

      it 'should be standard queue' do
        expect(standard_queue.standard?).to eq true
      end

      it 'should be command queue' do
        expect(standard_queue.kind).to eq :command
      end

      it 'should create expected queue' do
        expect(standard_queue.arn).to eq 'arn:aws:sqs:region:42:test-command-queue-sample_app-notes_was_added.fifo'
      end
    end

    context 'when dest is defined' do
      subject(:standard_queue) { client.queue('notes_was_added', fifo: true, dest: :mailer) }

      it { is_expected.to be_a CycloneLariat::Resources::Queue }

      it 'should be standard queue' do
        expect(standard_queue.dest).to eq :mailer
      end

      it 'should create expected queue' do
        expect(standard_queue.arn).to eq 'arn:aws:sqs:region:42:test-event-queue-sample_app-notes_was_added-mailer.fifo'
      end
    end
  end

  describe '#exists?' do
    subject(:exists?) { client.exists? client.queue(:create_note, fifo: true) }

    context 'when queue already exists' do
      it { is_expected.to be true }
    end

    context 'when queue does not exists' do
      before do
        error = Aws::SQS::Errors.error_class('NonExistentQueue').new('message', 'context')
        allow(aws_sqs_client).to receive(:get_queue_url).and_raise error
      end

      it { is_expected.to be false }
    end
  end

  describe 'create' do
    subject(:create) do
      client.create client.queue(:note_created, fifo: true, content_based_deduplication: true)
    end

    context 'when queue already exists' do
      it 'should raise error' do
        expect { create }.to raise_error CycloneLariat::Errors::QueueAlreadyExists
      end
    end

    context 'when queue does not exists and create FIFO' do
      before do
        error = Aws::SQS::Errors.error_class('NonExistentQueue').new('message', 'context')
        allow(aws_sqs_client).to receive(:get_queue_url).and_raise error
      end

      it 'should create new one FIFO queue' do
        expect(aws_sqs_client).to receive(:create_queue).with(
          queue_name: 'test-event-queue-sample_app-note_created.fifo',
          attributes: { 'FifoQueue' => 'true', 'ContentBasedDeduplication' => 'true' },
          tags: {
            'standard' => 'true',
            'instance' => 'test',
            'kind' => 'event',
            'publisher' => 'sample_app',
            'type' => 'note_created',
            'dest' => 'undefined',
            'fifo' => 'true'
          }
        )
        create
      end
    end

    context 'when queue does not exists and create non-FIFO' do
      subject(:create) { client.create client.queue(:note_created, fifo: false) }

      before do
        error = Aws::SQS::Errors.error_class('NonExistentQueue').new('message', 'context')
        allow(aws_sqs_client).to receive(:get_queue_url).and_raise error
      end

      it 'should create new one non-FIFO queue' do
        expect(aws_sqs_client).to receive(:create_queue).with(
          queue_name: 'test-event-queue-sample_app-note_created',
          attributes: {},
          tags: {
            'standard' => 'true',
            'instance' => 'test',
            'kind' => 'event',
            'publisher' => 'sample_app',
            'type' => 'note_created',
            'dest' => 'undefined',
            'fifo' => 'false'
          }
        )
        create
      end
    end
  end

  describe 'delete' do
    subject(:delete) { client.delete client.queue(:notes_created, fifo: true) }

    context 'when queue does not exists' do
      before do
        error = Aws::SQS::Errors.error_class('NonExistentQueue').new('message', 'context')
        allow(aws_sqs_client).to receive(:get_queue_url).and_raise error
      end

      it 'should raise error' do
        expect { delete }.to raise_error CycloneLariat::Errors::QueueDoesNotExists
      end
    end

    context 'when queue already exists' do
      it 'should delete new one queue' do
        expect(aws_sqs_client).to receive(:delete_queue).with(
          queue_url: 'https://sqs.region.amazonaws.com/42/test-event-queue-sample_app-notes_created.fifo'
        )
        delete
      end
    end
  end

  describe '#publish' do
    let(:request_id) { SecureRandom.uuid }
    let(:event) { client.event('create_note', data: { text: 'Test note' }, request_id: request_id, group_id: 'the.group') }
    subject(:publish_event) { client.publish event, fifo: true }

    context 'when topic does not exists' do
      before { allow(aws_sqs_client).to receive(:send_message).and_raise(Aws::SQS::Errors::NotFound.new('context', 'message')) }

      it 'should raise not found topic error' do
        expect { publish_event }.to raise_error Aws::SQS::Errors::NotFound
      end
    end

    context 'in existed FIFO topic' do
      let(:expected_message) do
        {
          uuid: event.uuid,
          publisher: 'sample_app',
          type: 'event_create_note',
          version: 1,
          data: { text: 'Test note' },
          request_id: request_id,
          sent_at: event.sent_at.iso8601(3)
        }
      end

      context 'when group_id does not defined' do
        let(:event) { client.event('create_note', data: { text: 'Test note' }, request_id: request_id, group_id: nil) }

        it 'should raise you must define group id' do
          expect { publish_event }.to raise_error CycloneLariat::Errors::GroupIdUndefined
        end
      end

      context 'when topic generated by message' do
        it 'should be sent to topic expected message' do
          expect(aws_sqs_client).to receive(:send_message).with(
            message_body: expected_message.to_json,
            queue_url: 'https://sqs.region.amazonaws.com/42/test-event-queue-sample_app-create_note.fifo',
            message_group_id: 'the.group'
          )
          publish_event
        end
      end

      context 'custom topic' do
        subject(:publish_event) { client.publish event, queue: 'defined_topic.fifo', fifo: true }

        it 'should be sent to topic expected message' do
          expect(aws_sqs_client).to receive(:send_message).with(
            message_body: expected_message.to_json,
            queue_url: 'https://sqs.region.amazonaws.com/42/defined_topic.fifo',
            message_group_id: 'the.group'
          )
          publish_event
        end
      end

      context 'when deduplication_id defined' do
        let(:event) do
          client.event(
            'create_note',
            data: { text: 'Test note' },
            request_id: request_id,
            group_id: 'the.group',
            deduplication_id: 'the.uniq'
          )
        end

        it 'should be sent to topic expected message' do
          expect(aws_sqs_client).to receive(:send_message).with(
            message_body: expected_message.to_json,
            queue_url: 'https://sqs.region.amazonaws.com/42/test-event-queue-sample_app-create_note.fifo',
            message_group_id: 'the.group',
            message_deduplication_id: 'the.uniq'
          )
          publish_event
        end
      end

      context 'when message invalid' do
        let(:event) { client.event('create_user', data: { text: 'Test note' }, request_id: 'no-uuid', group_id: 'the.group') }

        it 'should have invalid message' do
          expect(event.valid?).to eq false
        end

        context 'and validation is enabled' do
          subject(:publish_event) { client.publish event, queue: 'defined_queue.fifo', fifo: true, skip_validation: false }

          it { expect { publish_event }.to raise_error CycloneLariat::Errors::InvalidMessage }
        end

        context 'and validation is disabled' do
          subject(:publish_event) { client.publish event, queue: 'defined_queue.fifo', fifo: true, skip_validation: true }
          before { allow(aws_sqs_client).to receive(:send_message).and_return(nil) }

          it { expect { publish_event }.to_not raise_error }
        end
      end
    end

    context 'in existed non-FIFO topic' do
      let(:event) { client.event('create_note', data: { text: 'Test note' }, request_id: request_id) }
      subject(:publish_event) { client.publish event, fifo: false }

      let(:expected_message) do
        {
          uuid: event.uuid,
          publisher: 'sample_app',
          type: 'event_create_note',
          version: 1,
          data: { text: 'Test note' },
          request_id: request_id,
          sent_at: event.sent_at.iso8601(3)
        }
      end

      context 'when group_id is defined' do
        let(:event) { client.event('create_note', data: { text: 'Test note' }, request_id: request_id, group_id: 'the.group') }

        it 'should raise you must define group id' do
          expect { publish_event }.to raise_error CycloneLariat::Errors::GroupDefined
        end
      end

      context 'when deduplication_id is defined' do
        let(:event) { client.event('create_note', data: { text: 'Test note' }, request_id: request_id, deduplication_id: 'the.group') }

        it 'should raise you must define group id' do
          expect { publish_event }.to raise_error CycloneLariat::Errors::DeduplicationIdDefined
        end
      end

      context 'when topic generated by message' do
        it 'should be sent to topic expected message' do
          expect(aws_sqs_client).to receive(:send_message).with(
            message_body: expected_message.to_json,
            queue_url: 'https://sqs.region.amazonaws.com/42/test-event-queue-sample_app-create_note'
          )
          publish_event
        end
      end

      context 'custom queue' do
        subject(:publish_event) { client.publish event, queue: 'defined_topic', fifo: false }

        it 'should be sent to topic expected message' do
          expect(aws_sqs_client).to receive(:send_message).with(
            message_body: expected_message.to_json,
            queue_url: 'https://sqs.region.amazonaws.com/42/defined_topic'
          )
          publish_event
        end
      end
    end

    context 'when fake publish' do
      before { allow(client.config).to receive(:fake_publish).and_return(true) }

      it 'should not send message' do
        expect(aws_sqs_client).not_to receive(:send_message)
      end

      it 'should return fake response' do
        expect(publish_event).to be_instance_of(Aws::SQS::Types::SendMessageResult)
      end
    end
  end

  describe '#list_all' do
    let(:first_page) do
      {
        queue_urls: %w[
          https://sqs.eu-west-1.amazonaws.com/247606935658/test-event-queue-cyclone_lariat-note_added.fifo
          https://sqs.eu-west-1.amazonaws.com/247606935658/test-event-queue-cyclone_lariat-cubs_added.fifo
        ],
        next_token: 'page_2'
      }
    end

    let(:second_page) do
      {
        queue_urls: [
          'https://sqs.eu-west-1.amazonaws.com/247606935658/test-event-queue-cyclone_lariat-chip_added.fifo'
        ],
        next_token: nil
      }
    end

    before do
      allow(aws_sqs_client).to receive(:list_queues).with(next_token: 'page_2').and_return(second_page)
      allow(aws_sqs_client).to receive(:list_queues).with(no_args).and_return(first_page)
    end

    subject(:list_all) { client.list_all }

    it 'should return array of Queues' do
      is_expected.to all(be_an(CycloneLariat::Resources::Queue))
    end

    it 'should generate list of expected queues' do
      expect(list_all.map(&:arn)).to eq %w[
        arn:aws:sqs:eu-west-1:247606935658:test-event-queue-cyclone_lariat-note_added.fifo
        arn:aws:sqs:eu-west-1:247606935658:test-event-queue-cyclone_lariat-cubs_added.fifo
        arn:aws:sqs:eu-west-1:247606935658:test-event-queue-cyclone_lariat-chip_added.fifo
      ]
    end
  end
end
