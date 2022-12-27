# frozen_string_literal: true

require 'cyclone_lariat/core'
require 'cyclone_lariat/presenters/queues'

RSpec.describe CycloneLariat::Presenters::Queues do
  let(:queues_presenter) { described_class.new }

  describe '#call' do
    subject(:table) { queues_presenter.call(queues) }

    context 'when subscriptions is empty' do
      let(:queues) { [] }

      it 'should return table ' do
        is_expected.to be_a Terminal::Table
      end

      let(:expected_table) do
        table = <<~TABLE
          +-------+--------+------------+------+----------+------+-----------+------+-------------+------+
          | valid | region | account_id | name | instance | kind | publisher | type | destination | fifo |
          +-------+--------+------------+------+----------+------+-----------+------+-------------+------+
          +----------------------------------------------------------------------------------------------+
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
          publisher: 'queues_test'
        )
      end

      let(:queues) do
        [
          CycloneLariat.queue(:first_queue, fifo: true, **options.to_h),
          CycloneLariat.queue(:second_queue, fifo: true, **options.to_h)
        ]
      end

      let(:expected_table) do
        table = <<~TABLE
          +----------+--------+------------+------------------------------------------------+----------+-------+-------------+--------------+-------------+------+
          | valid    | region | account_id | name                                           | instance | kind  | publisher   | type         | destination | fifo |
          +----------+--------+------------+------------------------------------------------+----------+-------+-------------+--------------+-------------+------+
          | standard |        |            | test-event-queue-queues_test-first_queue.fifo  | test     | event | queues_test | first_queue  |             | true |
          | standard |        |            | test-event-queue-queues_test-second_queue.fifo | test     | event | queues_test | second_queue |             | true |
          +----------+--------+------------+------------------------------------------------+----------+-------+-------------+--------------+-------------+------+
        TABLE

        table[0...-1]
      end

      it 'should return table with expected rows' do
        expect(table.to_s).to eq(expected_table)
      end
    end
  end
end
