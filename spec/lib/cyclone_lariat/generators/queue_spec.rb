# frozen_string_literal: true

require 'cyclone_lariat/generators/queue'
require 'cyclone_lariat/options'

RSpec.describe CycloneLariat::Generators::Queue do
  let(:class_with_generator) do
    Class.new do
      include CycloneLariat::Generators::Queue

      def config
        CycloneLariat::Options.new(
          instance: 'test',
          publisher: 'pizzeria',
          aws_account_id: 'account_id',
          version: 1
        )
      end
    end
  end

  let(:object_with_generator) { class_with_generator.new }

  describe '#queue' do
    subject(:queue) do
      object_with_generator.queue 'pizza_line', fifo: true, content_based_deduplication: true
    end

    it { is_expected.to be_a CycloneLariat::Resources::Queue }

    it 'should match expected values' do
      expect(queue.instance).to be 'test'
      expect(queue.kind).to be :event
      expect(queue.fifo).to be true
      expect(queue.dest).to be_nil
      expect(queue.account_id).to eq 'account_id'
      expect(queue.publisher).to eq 'pizzeria'
      expect(queue.type).to eq 'pizza_line'
      expect(queue.fifo).to eq true
      expect(queue.content_based_deduplication).to eq true
      expect(queue.tags).to eq({
        'standard' => 'true',
        'instance' => 'test',
        'kind' => 'event',
        'publisher' => 'pizzeria',
        'type' => 'pizza_line',
        'dest' => 'undefined',
        'fifo' => 'true'
      })
    end
  end

  describe '#custom_queue' do
    subject(:queue) { object_with_generator.custom_queue 'pizza_line.fifo' }

    it { is_expected.to be_a CycloneLariat::Resources::Queue }

    it 'should match expected values' do
      expect(queue.instance).to be_nil
      expect(queue.kind).to be_nil
      expect(queue.fifo).to eq(true)
      expect(queue.account_id).to eq('account_id')
      expect(queue.publisher).to be_nil
      expect(queue.type).to be_nil
      expect(queue.fifo).to eq(true)
      expect(queue.name).to eq('pizza_line.fifo')
      expect(queue.tags).to eq({
        'standard' => 'false',
        'name' => 'pizza_line.fifo',
        'fifo' => 'true'
      })
    end
  end
end
