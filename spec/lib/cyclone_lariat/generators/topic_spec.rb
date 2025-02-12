# frozen_string_literal: true

require 'cyclone_lariat/generators/topic'
require 'cyclone_lariat/options'

RSpec.describe CycloneLariat::Generators::Topic do
  let(:class_with_generator) do
    Class.new do
      include CycloneLariat::Generators::Topic

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
    subject(:topic) do
      object_with_generator.topic 'pizza_line', fifo: true, content_based_deduplication: true
    end

    it { is_expected.to be_a CycloneLariat::Resources::Topic }

    it 'should match expected values' do
      expect(topic.instance).to be 'test'
      expect(topic.kind).to be :event
      expect(topic.fifo).to be true
      expect(topic.account_id).to eq 'account_id'
      expect(topic.publisher).to eq 'pizzeria'
      expect(topic.type).to eq 'pizza_line'
      expect(topic.fifo).to eq true
      expect(topic.content_based_deduplication).to eq true
      expect(topic.tags).to eq([
                                 { key: 'standard', value: 'true' },
                                 { key: 'instance', value: 'test' },
                                 { key: 'kind', value: 'event' },
                                 { key: 'publisher', value: 'pizzeria' },
                                 { key: 'type', value: 'pizza_line' },
                                 { key: 'fifo', value: 'true' }
                               ])
    end
  end

  describe '#custom_queue' do
    subject(:topic) { object_with_generator.custom_topic 'pizza_line.fifo' }

    it { is_expected.to be_a CycloneLariat::Resources::Topic }

    it 'should match expected values' do
      expect(topic.instance).to be_nil
      expect(topic.kind).to be_nil
      expect(topic.fifo).to eq(true)
      expect(topic.account_id).to eq('account_id')
      expect(topic.publisher).to be_nil
      expect(topic.type).to be_nil
      expect(topic.fifo).to eq(true)
      expect(topic.name).to eq('pizza_line.fifo')
      expect(topic.tags).to eq([
                                 { key: 'standard', value: 'false' },
                                 { key: 'name', value: 'pizza_line.fifo' },
                                 { key: 'fifo', value: 'true' }
                               ])
    end
  end
end
