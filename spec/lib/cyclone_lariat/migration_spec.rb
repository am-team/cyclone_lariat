# frozen_string_literal: true

require_relative '../../../lib/cyclone_lariat/migration'

RSpec.describe CycloneLariat::Migration do
  let(:migration) { Class.new(described_class).new }
  let(:topic) do
    CycloneLariat::Resources::Topic.new(
      instance: 'test',
      publisher: 'cyclone_lariat',
      region: 'region',
      account_id: 42,
      kind: :event,
      type: :notes_added,
      fifo: true
    )
  end

  let(:queue) do
    CycloneLariat::Resources::Queue.new(
      instance: 'test',
      publisher: 'cyclone_lariat',
      region: 'region',
      account_id: 42,
      kind: :event,
      type: :notes_added,
      dest: nil,
      fifo: true
    )
  end

  describe '#create' do
    subject(:create) { migration.create resource }

    let(:sns) { instance_double CycloneLariat::Clients::Sns, create: true }
    let(:sqs) { instance_double CycloneLariat::Clients::Sqs, create: true }

    before do
      migration.dependencies = { sns: -> { sns }, sqs: -> { sqs } }
    end

    context 'when resource is a topic' do
      let(:resource) { topic }

      it 'should create sns topic' do
        expect(sns).to receive(:create).with(resource)
        create
      end
    end

    context 'when resource is a queue' do
      let(:resource) { queue }

      it 'should create sns topic' do
        expect(sqs).to receive(:create).with(resource)
        create
      end
    end

    context 'when resource has undefined class' do
      let(:resource) { double }

      it 'should create sns topic' do
        expect { create }.to raise_error ArgumentError
      end
    end
  end

  describe '#delete' do
    subject(:delete) { migration.delete resource }

    let(:sns) { instance_double CycloneLariat::Clients::Sns, delete: true }
    let(:sqs) { instance_double CycloneLariat::Clients::Sqs, delete: true }

    before do
      migration.dependencies = { sns: -> { sns }, sqs: -> { sqs } }
    end

    context 'when resource is a topic' do
      let(:resource) { topic }

      it 'should delete sns topic' do
        expect(sns).to receive(:delete).with(resource)
        delete
      end
    end

    context 'when resource is a queue' do
      let(:resource) { queue }

      it 'should delete sns topic' do
        expect(sqs).to receive(:delete).with(resource)
        delete
      end
    end

    context 'when resource has undefined class' do
      let(:resource) { double }

      it 'should delete sns topic' do
        expect { delete }.to raise_error ArgumentError
      end
    end
  end

  describe '#exists?' do
    subject(:exists?) { migration.exists? resource }

    let(:sns) { instance_double CycloneLariat::Clients::Sns, exists?: true }
    let(:sqs) { instance_double CycloneLariat::Clients::Sqs, exists?: true }

    before do
      migration.dependencies = { sns: -> { sns }, sqs: -> { sqs } }
    end

    context 'when resource is a topic' do
      let(:resource) { topic }

      it 'should exists? sns topic' do
        expect(sns).to receive(:exists?).with(resource)
        exists?
      end
    end

    context 'when resource is a queue' do
      let(:resource) { queue }

      it 'should exists? sns topic' do
        expect(sqs).to receive(:exists?).with(resource)
        exists?
      end
    end

    context 'when resource has undefined class' do
      let(:resource) { double }

      it 'should exists? sns topic' do
        expect { exists? }.to raise_error ArgumentError
      end
    end
  end

  describe '#subscribe' do
    let(:sns) { instance_double CycloneLariat::Clients::Sns, subscribe: true }
    let(:sqs) { instance_double CycloneLariat::Clients::Sqs, add_policy: true }

    before do
      migration.dependencies = {
        sns: -> { sns },
        sqs: -> { sqs }
      }
    end

    context 'when endpoint is topic' do
      subject(:subscribe) { migration.subscribe topic: topic, endpoint: topic }

      it 'should not add policy' do
        expect(sqs).to_not receive(:add_policy)
        subscribe
      end

      it 'should subscribe endpoint to sns topic' do
        expect(sns).to receive(:subscribe).with(topic: topic, endpoint: topic)
        subscribe
      end
    end

    context 'when endpoint is queue' do
      subject(:subscribe) { migration.subscribe topic: topic, endpoint: queue }

      before { CycloneLariat.config.aws_account_id = '123456' }
      after  { CycloneLariat.config.aws_account_id = nil }

      it 'should add policy to sqs queue' do
        expected_policy = {
          'Action' => 'SQS:*',
          'Condition' => {
            'ArnEquals' => {
              'aws:SourceArn' => 'arn:aws:sns:region:42:test-event-fanout-cyclone_lariat-notes_added.fifo'
            }
          },
          'Effect' => 'Allow',
          'Principal' => {
              'AWS' => '123456'
            },
          'Resource' => 'arn:aws:sqs:region:42:test-event-queue-cyclone_lariat-notes_added.fifo',
          'Sid' => 'test-event-fanout-cyclone_lariat-notes_added.fifo'
        }

        expect(sqs).to receive(:add_policy).with(queue: queue, policy: expected_policy)
        subscribe
      end

      it 'should subscribe endpoint to sns topic' do
        expect(sns).to receive(:subscribe).with(topic: topic, endpoint: queue)
        subscribe
      end
    end
  end

  describe '#unsubscribe' do
    subject(:unsubscribe) { migration.unsubscribe topic: topic, endpoint: queue }

    let(:sns) { instance_double CycloneLariat::Clients::Sns, unsubscribe: true }

    before do
      migration.dependencies = { sns: -> { sns } }
    end

    it 'should subscribe endpoint to sns topic' do
      expect(sns).to receive(:unsubscribe).with(topic: topic, endpoint: queue)
      unsubscribe
    end
  end

  describe '#topics' do
    subject(:topics) { migration.topics }

    let(:sns) { instance_double CycloneLariat::Clients::Sns, list_all: [] }

    before do
      migration.dependencies = { sns: -> { sns } }
    end

    it 'should list all SNS topics' do
      expect(sns).to receive(:list_all)
      topics
    end
  end

  describe '#subscriptions' do
    subject(:subscriptions) { migration.subscriptions }

    let(:sns) { instance_double CycloneLariat::Clients::Sns, list_subscriptions: [] }

    before do
      migration.dependencies = { sns: -> { sns } }
    end

    it 'should list all SNS subscriptions' do
      expect(sns).to receive(:list_subscriptions)
      subscriptions
    end
  end

  describe '#queues' do
    subject(:queues) { migration.queues }

    let(:sqs) { instance_double CycloneLariat::Clients::Sqs, list_all: [] }

    before do
      migration.dependencies = { sqs: -> { sqs } }
    end

    it 'should list all SQS queues' do
      expect(sqs).to receive(:list_all)
      queues
    end
  end

  describe '.migrate' do
  end
end
