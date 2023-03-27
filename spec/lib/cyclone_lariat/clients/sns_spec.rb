# frozen_string_literal: true

require 'cyclone_lariat/clients/sqs'
require 'cyclone_lariat/clients/sns'
require 'timecop'

RSpec.describe CycloneLariat::Clients::Sns do
  let(:client) do
    described_class.new(
      aws_key: 'key',
      aws_secret_key: 'secret_key',
      aws_region: 'region',
      aws_account_id: 42,
      publisher: 'sample_app',
      instance: :test,
      version: 1
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

    it { is_expected.to be_a CycloneLariat::Resources::Topic }

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

      it { is_expected.to be_a CycloneLariat::Resources::Topic }

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

      it { is_expected.to be_a CycloneLariat::Resources::Topic }

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

      it { is_expected.to be_a CycloneLariat::Resources::Topic }

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
    subject(:create_topic) do
      client.create client.topic('create_note', fifo: true, content_based_deduplication: true)
    end

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
          attributes: { 'FifoTopic' => 'true', 'ContentBasedDeduplication' => 'true' },
          tags: [
            { key: 'standard', value: 'true' },
            { key: 'instance', value: 'test' },
            { key: 'kind', value: 'event' },
            { key: 'publisher', value: 'sample_app' },
            { key: 'type', value: 'create_note' },
            { key: 'fifo', value: 'true' }
          ]
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
            { key: 'standard', value: 'true' },
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
    let(:request_id) { SecureRandom.uuid }
    let(:event) { client.event('create_note', data: { text: 'Test note' }, request_id: request_id, group_id: 'the.group') }
    subject(:publish_event) { client.publish event, fifo: true }

    context 'when topic does not exists' do
      before { allow(aws_sns_client).to receive(:publish).and_raise(Aws::SNS::Errors::NotFound.new('context', 'message')) }

      it 'should raise not found topic error' do
        expect { publish_event }.to raise_error Aws::SNS::Errors::NotFound
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
          expect(aws_sns_client).to receive(:publish).with(
            message: expected_message.to_json,
            topic_arn: 'arn:aws:sns:region:42:test-event-fanout-sample_app-create_note.fifo',
            message_group_id: 'the.group'
          )
          publish_event
        end
      end

      context 'custom topic' do
        subject(:publish_event) { client.publish event, topic: 'defined_topic.fifo', fifo: true }

        it 'should be sent to topic expected message' do
          expect(aws_sns_client).to receive(:publish).with(
            message: expected_message.to_json,
            topic_arn: 'arn:aws:sns:region:42:defined_topic.fifo',
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
          expect(aws_sns_client).to receive(:publish).with(
            message: expected_message.to_json,
            topic_arn: 'arn:aws:sns:region:42:test-event-fanout-sample_app-create_note.fifo',
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
          subject(:publish_event) { client.publish event, topic: 'defined_topic.fifo', fifo: true, skip_validation: false }

          it { expect { publish_event }.to raise_error CycloneLariat::Errors::InvalidMessage }
        end

        context 'and validation is disabled' do
          subject(:publish_event) { client.publish event, topic: 'defined_topic.fifo', fifo: true, skip_validation: true }
          before { allow(aws_sns_client).to receive(:publish).and_return(nil) }

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

        it 'should raise group id must be nil' do
          expect { publish_event }.to raise_error CycloneLariat::Errors::GroupDefined
        end
      end

      context 'when topic generated by message' do
        it 'should be sent to topic expected message' do
          expect(aws_sns_client).to receive(:publish).with(
            message: expected_message.to_json,
            topic_arn: 'arn:aws:sns:region:42:test-event-fanout-sample_app-create_note'
          )
          publish_event
        end
      end

      context 'custom topic' do
        subject(:publish_event) { client.publish event, topic: 'defined_topic', fifo: false }

        it 'should be sent to topic expected message' do
          expect(aws_sns_client).to receive(:publish).with(
            message: expected_message.to_json,
            topic_arn: 'arn:aws:sns:region:42:defined_topic'
          )
          publish_event
        end
      end

      context 'when deduplication_id defined' do
        let(:event) do
          client.event('create_note', data: { text: 'Test note' }, request_id: request_id, deduplication_id: 'the.uniq')
        end

        it 'should raise deduplication id must be nil' do
          expect { publish_event }.to raise_error CycloneLariat::Errors::DeduplicationIdDefined
        end
      end
    end

    context 'when fake publish' do
      before { allow(client.config).to receive(:fake_publish).and_return(true) }

      it 'should not send message' do
        expect(aws_sns_client).not_to receive(:publish)
        publish_event
      end

      it 'should return fake response' do
        expect(publish_event).to be_instance_of(Aws::SNS::Types::PublishResponse)
      end
    end
  end

  describe '#subscribe' do
    let(:topic) { client.topic(:note_added, fifo: true) }
    let(:sqs_client) do
      CycloneLariat::Clients::Sqs.new(
        aws_key: 'key',
        aws_secret_key: 'secret_key',
        aws_region: 'region',
        aws_account_id: 42,
        publisher: 'sample_app',
        instance: :test,
        version: 1
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
        expect { subscribe }.to raise_error CycloneLariat::Errors::SubscriptionAlreadyExists
      end
    end

    context 'when subscription is not exists' do
      before do
        allow(aws_sns_client).to receive(:list_subscriptions_by_topic).with(topic_arn: topic.arn).and_return(
          {
            subscriptions: [],
            next_token: nil
          }
        )
      end

      it 'should create new subscription' do
        expect(aws_sns_client).to receive(:subscribe).with(
          {
            topic_arn: 'arn:aws:sns:region:42:test-event-fanout-sample_app-note_added.fifo',
            protocol: 'sqs',
            endpoint: 'arn:aws:sqs:region:42:test-event-queue-sample_app-note_added.fifo'
          }
        )
        subscribe
      end
    end
  end

  describe '#unsubscribe' do
    let(:topic) { client.topic(:note_added, fifo: true) }
    let(:sqs_client) do
      CycloneLariat::Clients::Sqs.new(
        aws_key: 'key',
        aws_secret_key: 'secret_key',
        aws_region: 'region',
        aws_account_id: 42,
        publisher: 'sample_app',
        instance: :test,
        version: 1
      )
    end

    let(:queue) { sqs_client.queue(:note_added, fifo: true) }
    subject(:unsubscribe) { client.unsubscribe(topic: topic, endpoint: queue) }

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
        expect(aws_sns_client).to receive(:unsubscribe).with(
          {
            subscription_arn: 'subscription_arn'
          }
        )
        unsubscribe
      end
    end

    context 'when subscription is not exists' do
      before do
        allow(aws_sns_client).to receive(:list_subscriptions_by_topic).with(topic_arn: topic.arn).and_return(
          {
            subscriptions: [],
            next_token: nil
          }
        )
      end

      it 'should create new subscription' do
        expect { unsubscribe }.to raise_error CycloneLariat::Errors::SubscriptionDoesNotExists
      end
    end
  end

  describe '#subscribed?' do
    let(:topic) { client.topic(:note_added, fifo: true) }
    let(:sqs_client) do
      CycloneLariat::Clients::Sqs.new(
        aws_key: 'key',
        aws_secret_key: 'secret_key',
        aws_region: 'region',
        aws_account_id: 42,
        publisher: 'sample_app',
        instance: :test,
        version: 1
      )
    end

    let(:queue) { sqs_client.queue(:note_added, fifo: true) }
    subject(:subscribed?) { client.subscribed?(topic: topic, endpoint: queue) }

    context 'when subscription already exists' do
      before do
        allow(aws_sns_client).to receive(:list_subscriptions_by_topic).with(topic_arn: topic.arn).and_return(
          {
            subscriptions: [instance_double(Aws::SNS::Types::Subscription, endpoint: queue.arn, subscription_arn: 'subscription_arn')],
            next_token: nil
          }
        )
      end

      it 'should be true' do
        expect(subscribed?).to be_truthy
      end
    end

    context 'when subscription is not exists' do
      before do
        allow(aws_sns_client).to receive(:list_subscriptions_by_topic).with(topic_arn: topic.arn).and_return(
          {
            subscriptions: [],
            next_token: nil
          }
        )
      end

      it 'should be false' do
        expect(subscribed?).to be_falsey
      end
    end
  end

  describe '#list_all' do
    let(:first_page) do
      {
        topics: [
          { topic_arn: 'arn:aws:sns:eu-west-1:247602342345:test-event-fanout-cyclone_lariat-note_added.fifo' },
          { topic_arn: 'arn:aws:sns:eu-west-1:247602342345:test-event-fanout-cyclone_lariat-cubs_added.fifo' }
        ],
        next_token: 'page_2'
      }
    end

    let(:second_page) do
      {
        topics: [
          { topic_arn: 'arn:aws:sns:eu-west-1:247602342345:test-event-fanout-cyclone_lariat-chip_added.fifo' }
        ],
        next_token: nil
      }
    end

    before do
      allow(aws_sns_client).to receive(:list_topics).with(next_token: 'page_2').and_return(second_page)
      allow(aws_sns_client).to receive(:list_topics).with(no_args).and_return(first_page)
    end

    subject(:list_all) { client.list_all }

    it 'should return array of Topics' do
      is_expected.to all(be_an(CycloneLariat::Resources::Topic))
    end

    it 'should generate list of expected queues' do
      expect(list_all.map(&:arn)).to eq %w[
        arn:aws:sns:eu-west-1:247602342345:test-event-fanout-cyclone_lariat-note_added.fifo
        arn:aws:sns:eu-west-1:247602342345:test-event-fanout-cyclone_lariat-cubs_added.fifo
        arn:aws:sns:eu-west-1:247602342345:test-event-fanout-cyclone_lariat-chip_added.fifo
      ]
    end
  end

  describe '#list_subscriptions' do
    let(:first_page) do
      {
        subscriptions: [
          Aws::SNS::Types::Subscription.new(
            endpoint: 'arn:aws:sqs:eu-west-1:247602342345:test-event-queue-office-user_country_is_changed-crm',
            owner: '247602342345',
            protocol: 'sqs',
            subscription_arn: 'arn:aws:sns:eu-west-1:247602342345:test-event-fanout-office-user_country_is_changed:1966be52-993c-4c7e-a07c-787d21376fd2',
            topic_arn: 'arn:aws:sns:eu-west-1:247602342345:test-event-fanout-office-user_country_is_changed'
          )
        ],
        next_token: 'page_2'
      }
    end

    let(:second_page) do
      {
        subscriptions: [
          Aws::SNS::Types::Subscription.new(
            endpoint: 'arn:aws:sns:eu-west-1:247602342345:test-event-fanout-office-user_country_is_changed',
            owner: '247602342345',
            protocol: 'sns',
            subscription_arn: 'arn:aws:sns:eu-west-1:247602342345:test-event-fanout-identify-phone_is_verified:e9946a60-54df-4d00-943c-4b2ff48891ac',
            topic_arn: 'arn:aws:sns:eu-west-1:247602342345:test-event-fanout-identify-phone_is_verified'
          ),
          Aws::SNS::Types::Subscription.new(
            endpoint: 'xxx@yyy.com',
            owner: '247602342345',
            protocol: 'email',
            subscription_arn: 'arn:aws:sns:eu-west-1:247602342345:test_CloudWatch_Alarms_Topic:7cf4b48b-c6ff-4f2f-a904-871b2c9e5822',
            topic_arn: 'arn:aws:sns:eu-west-1:247602342345:test_CloudWatch_Alarms_Topic'
          )
        ],
        next_token: nil
      }
    end

    before do
      allow(aws_sns_client).to receive(:list_subscriptions).with(next_token: 'page_2').and_return(second_page)
      allow(aws_sns_client).to receive(:list_subscriptions).with(no_args).and_return(first_page)
    end

    subject(:list_subscriptions) { client.list_subscriptions }

    it 'should generate list of expected subscriptions' do
      expect(list_subscriptions.map { |s| { topic: s[:topic].name, endpoint: s[:endpoint].name } }).to match_array(
        [
          {
            topic: CycloneLariat::Resources::Topic.from_arn(first_page[:subscriptions].first.topic_arn).name,
            endpoint: CycloneLariat::Resources::Queue.from_arn(first_page[:subscriptions].first.endpoint).name
          },
          {
            topic: CycloneLariat::Resources::Topic.from_arn(second_page[:subscriptions].first.topic_arn).name,
            endpoint: CycloneLariat::Resources::Topic.from_arn(second_page[:subscriptions].first.endpoint).name
          }
        ]
      )
    end
  end
end
