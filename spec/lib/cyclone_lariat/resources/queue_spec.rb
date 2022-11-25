# frozen_string_literal: true

require 'cyclone_lariat/resources/queue'

RSpec.describe CycloneLariat::Resources::Queue do
  describe '.from_arn' do
    context 'when send not arn' do
      subject(:queue) { described_class.from_arn 'custom_queue' }

      it { expect { queue }.to raise_error ArgumentError }
    end

    context 'when send not aws' do
      subject(:queue) { described_class.from_arn 'arn:not_aws:custom_queue' }

      it { expect { queue }.to raise_error ArgumentError }
    end

    context 'when send not sqs' do
      subject(:queue) { described_class.from_arn 'arn:aws:sns:custom_queue' }

      it { expect { queue }.to raise_error ArgumentError }
    end

    context 'custom queue' do
      subject(:queue) { described_class.from_arn 'arn:aws:sqs:eu-west-1:247606935658:custom_queue' }

      it { is_expected.to be_a CycloneLariat::Resources::Queue }

      it 'should be custom' do
        expect(queue.custom?).to be true
      end

      it 'should has expected attributes' do
        expect(queue.arn).to eq 'arn:aws:sqs:eu-west-1:247606935658:custom_queue'
        expect(queue.name).to eq 'custom_queue'
        expect(queue.account_id).to eq '247606935658'
        expect(queue.region).to eq 'eu-west-1'
      end
    end

    context 'standard queue' do
      subject(:queue) { described_class.from_arn 'arn:aws:sqs:eu-west-1:247606935658:test-event-queue-cyclone_lariat-note_added.fifo' }

      it { is_expected.to be_a CycloneLariat::Resources::Queue }

      it 'should be custom' do
        expect(queue.standard?).to be true
      end

      it 'should has expected attributes' do
        expect(queue.arn).to eq 'arn:aws:sqs:eu-west-1:247606935658:test-event-queue-cyclone_lariat-note_added.fifo'
        expect(queue.name).to eq 'test-event-queue-cyclone_lariat-note_added.fifo'
        expect(queue.account_id).to eq '247606935658'
        expect(queue.region).to eq 'eu-west-1'
        expect(queue.instance).to eq 'test'
        expect(queue.kind).to eq 'event'
        expect(queue.publisher).to eq 'cyclone_lariat'
        expect(queue.type).to eq 'note_added'
        expect(queue.fifo).to eq true
      end
    end
  end

  describe '.from_name' do
    subject(:queue) { described_class.from_name 'test-event-queue-cyclone_lariat-note_added.fifo', region: 'eu-west-1', account_id: 247_606_935_658 }

    it { is_expected.to be_a CycloneLariat::Resources::Queue }

    it 'should be created expected queue' do
      expect(queue.arn).to eq 'arn:aws:sqs:eu-west-1:247606935658:test-event-queue-cyclone_lariat-note_added.fifo'
    end
  end

  describe '.from_url' do
    subject(:queue) { described_class.from_url 'https://sqs.eu-west-1.amazonaws.com/247606935658/test-event-queue-cyclone_lariat-note_added.fifo' }

    it 'should be created expected queue' do
      expect(queue.arn).to eq 'arn:aws:sqs:eu-west-1:247606935658:test-event-queue-cyclone_lariat-note_added.fifo'
    end

    context 'when url not url format' do
      subject(:queue) { described_class.from_url 'example text' }

      it { expect { queue }.to raise_error(ArgumentError, 'Url is not http format') }
    end

    context 'when url not https format' do
      subject(:queue) { described_class.from_url 'http://sqs.eu-west-1.amazonaws.com/247606935658/test-event-queue-cyclone_lariat-note_added.fifo' }

      it { expect { queue }.to raise_error ArgumentError, 'Url should start from https' }
    end

    context 'when url not has not sqs' do
      subject(:queue) { described_class.from_url 'https://sns.eu-west-1.amazonaws.com/247606935658/test-event-queue-cyclone_lariat-note_added.fifo' }

      it { expect { queue }.to raise_error(ArgumentError, 'It is not queue url') }
    end
  end
end
