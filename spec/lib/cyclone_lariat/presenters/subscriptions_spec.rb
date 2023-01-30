# frozen_string_literal: true

require 'cyclone_lariat/core'
require 'cyclone_lariat/presenters/subscriptions'

RSpec.describe CycloneLariat::Presenters::Subscriptions do
  let(:subscriptions_presenter) { described_class.new }

  describe '#call' do
    subject(:table) { subscriptions_presenter.call(subscriptions) }

    context 'when subscriptions is empty' do
      let(:subscriptions) { [] }

      it 'should return table ' do
        is_expected.to be_a Terminal::Table
      end

      let(:expected_table) do
        table = <<~TABLE
          +-------+----------+------------------+
          | topic | endpoint | subscription_arn |
          +-------+----------+------------------+
          +-------------------------------------+
        TABLE

        table[0...-1]
      end

      it 'should return empty table with expected rows' do
        expect(table.to_s).to eq(expected_table)
      end
    end

    context 'when we have some subscriptions' do
      let(:options) do
        CycloneLariat::Options.new(
          instance: 'test',
          publisher: 'subscriptions_test'
        )
      end

      let(:subscriptions) do
        [
          {
            topic: CycloneLariat.topic(:parent_topic, fifo: true, **options.to_h),
            endpoint: CycloneLariat.topic(:child_topic, fifo: true, **options.to_h),
            arn: 'first.arn'
          },
          {
            topic: CycloneLariat.topic(:parent_topic, fifo: true, **options.to_h),
            endpoint: CycloneLariat.queue(:child_queue, fifo: true, **options.to_h),
            arn: 'second.arn'
          }
        ]
      end

      let(:expected_table) do
        table = <<~TABLE
          +--------------------------------------------------------+-------------------------------------------------------+------------------+
          | topic                                                  | endpoint                                              | subscription_arn |
          +--------------------------------------------------------+-------------------------------------------------------+------------------+
          | test-event-fanout-subscriptions_test-parent_topic.fifo | test-event-fanout-subscriptions_test-child_topic.fifo | first.arn        |
          | test-event-fanout-subscriptions_test-parent_topic.fifo | test-event-queue-subscriptions_test-child_queue.fifo  | second.arn       |
          +--------------------------------------------------------+-------------------------------------------------------+------------------+
        TABLE

        table[0...-1]
      end

      it 'should return table with expected rows' do
        expect(table.to_s).to eq(expected_table)
      end
    end
  end
end
