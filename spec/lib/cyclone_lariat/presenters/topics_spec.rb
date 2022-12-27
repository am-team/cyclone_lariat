# frozen_string_literal: true

require 'cyclone_lariat/core'
require 'cyclone_lariat/presenters/topics'

RSpec.describe CycloneLariat::Presenters::Topics do
  let(:topics_presenter) { described_class.new }

  describe '#call' do
    subject(:table) { topics_presenter.call(topics) }

    context 'when subscriptions is empty' do
      let(:topics) { [] }

      it 'should return table ' do
        is_expected.to be_a Terminal::Table
      end

      let(:expected_table) do
        table = <<~TABLE
          +-------+--------+------------+------+----------+------+-----------+------+------+
          | valid | region | account_id | name | instance | kind | publisher | type | fifo |
          +-------+--------+------------+------+----------+------+-----------+------+------+
          +--------------------------------------------------------------------------------+
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
          publisher: 'topics_test'
        )
      end

      let(:topics) do
        [
          CycloneLariat.topic(:first_topic, fifo: true, **options.to_h),
          CycloneLariat.topic(:second_topic, fifo: true, **options.to_h)
        ]
      end

      let(:expected_table) do
        table = <<~TABLE
          +----------+--------+------------+-------------------------------------------------+----------+-------+-------------+--------------+------+
          | valid    | region | account_id | name                                            | instance | kind  | publisher   | type         | fifo |
          +----------+--------+------------+-------------------------------------------------+----------+-------+-------------+--------------+------+
          | standard |        |            | test-event-fanout-topics_test-first_topic.fifo  | test     | event | topics_test | first_topic  | true |
          | standard |        |            | test-event-fanout-topics_test-second_topic.fifo | test     | event | topics_test | second_topic | true |
          +----------+--------+------------+-------------------------------------------------+----------+-------+-------------+--------------+------+
        TABLE

        table[0...-1]
      end

      it 'should return table with expected rows' do
        expect(table.to_s).to eq(expected_table)
      end
    end
  end
end
