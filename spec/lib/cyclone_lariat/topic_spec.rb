# frozen_string_literal: true

require_relative '../../../lib/cyclone_lariat/topic'

RSpec.describe CycloneLariat::Topic do
  describe '.from_arn' do
    context 'when send not arn' do
      subject(:topic) { described_class.from_arn 'custom_queue' }

      it { expect { topic }.to raise_error ArgumentError }
    end

    context 'when send not aws' do
      subject(:topic) { described_class.from_arn 'arn:not_aws:custom_queue' }

      it { expect { topic }.to raise_error ArgumentError }
    end

    context 'when send not sns' do
      subject(:topic) { described_class.from_arn 'arn:aws:sqs:custom_queue' }

      it { expect { topic }.to raise_error ArgumentError }
    end

    context 'custom topic' do
      subject(:topic) { described_class.from_arn 'arn:aws:sns:eu-west-1:247606935658:custom_queue' }

      it { is_expected.to be_a CycloneLariat::Topic }

      it 'should be custom' do
        expect(topic.custom?).to be true
      end

      it 'should has expected attributes' do
        expect(topic.arn).to eq 'arn:aws:sns:eu-west-1:247606935658:custom_queue'
        expect(topic.name).to eq 'custom_queue'
        expect(topic.account_id).to eq '247606935658'
        expect(topic.region).to eq 'eu-west-1'
      end
    end

    context 'standard topic' do
      subject(:topic) { described_class.from_arn 'arn:aws:sns:eu-west-1:247606935658:test-event-topic-cyclone_lariat-note_added.fifo' }

      it { is_expected.to be_a CycloneLariat::Topic }

      it 'should be custom' do
        expect(topic.standard?).to be true
      end

      it 'should has expected attributes' do
        expect(topic.arn).to eq 'arn:aws:sns:eu-west-1:247606935658:test-event-topic-cyclone_lariat-note_added.fifo'
        expect(topic.name).to eq 'test-event-topic-cyclone_lariat-note_added.fifo'
        expect(topic.account_id).to eq '247606935658'
        expect(topic.region).to eq 'eu-west-1'
        expect(topic.instance).to eq 'test'
        expect(topic.kind).to eq 'event'
        expect(topic.publisher).to eq 'cyclone_lariat'
        expect(topic.type).to eq 'note_added'
        expect(topic.fifo).to eq true
      end
    end
  end

  describe '.from_name' do
    subject(:topic) { described_class.from_name 'test-event-topic-cyclone_lariat-note_added.fifo', region: 'eu-west-1', account_id: 247606935658 }

    it { is_expected.to be_a CycloneLariat::Topic }

    it 'should be created expected topic' do
      expect(topic.arn).to eq 'arn:aws:sns:eu-west-1:247606935658:test-event-topic-cyclone_lariat-note_added.fifo'
    end
  end
end
