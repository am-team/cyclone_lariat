# frozen_string_literal: true

require 'cyclone_lariat/core'
require 'cyclone_lariat/presenters/graph'

RSpec.describe CycloneLariat::Presenters::Graph do
  let(:graph_presenter) { described_class.new }

  describe '#call' do
    subject(:graph) { graph_presenter.call(subscriptions) }

    context 'when subscriptions is empty' do
      let(:subscriptions) { [] }

      it { is_expected.to eq('') }
    end

    context 'when we have some subscriptions' do
      let(:options) do
        CycloneLariat::Options.new(
          instance: 'test',
          publisher: 'graph_test'
        )
      end

      let(:subscriptions) do
        [
          {
            topic: CycloneLariat.topic(:parent_topic, fifo: true, **options.to_h),
            endpoint: CycloneLariat.topic(:child_topic, fifo: true, **options.to_h)
          },
          {
            topic: CycloneLariat.topic(:parent_topic, fifo: true, **options.to_h),
            endpoint: CycloneLariat.queue(:child_queue, fifo: true, **options.to_h)
          }
        ]
      end

      let(:expected_graph) do
        [
          "digraph G {\n  rankdir=LR;",
          '  "test-event-fanout-graph_test-parent_topic.fifo" [shape=component style=filled, fillcolor=white];',
          '  "test-event-fanout-graph_test-child_topic.fifo" [shape=component style=filled, fillcolor=white];',
          '  "test-event-fanout-graph_test-parent_topic.fifo" [shape=component style=filled, fillcolor=white];',
          '  "test-event-queue-graph_test-child_queue.fifo" [shape=record, style="rounded,filled", fillcolor=white];',
          '  "test-event-fanout-graph_test-parent_topic.fifo" -> "test-event-fanout-graph_test-child_topic.fifo";',
          '  "test-event-fanout-graph_test-parent_topic.fifo" -> "test-event-queue-graph_test-child_queue.fifo";',
          '}'
        ]
      end

      it 'should draw expected graph' do
        is_expected.to eq(expected_graph)
      end
    end
  end
end
