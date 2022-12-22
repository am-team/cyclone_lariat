# # frozen_string_literal: true
#
# require 'cyclone_lariat/generators/queue'
# require 'cyclone_lariat/options'
#
# RSpec.describe CycloneLariat::Generators::Topic do
#   let(:class_with_generator) do
#     Class.new do
#       include CycloneLariat::Generators::Topic
#
#       def config
#         CycloneLariat::Options.new(
#           instance: 'test',
#           publisher: 'pizzeria',
#           aws_account_id: 'account_id',
#           version: 1
#         )
#       end
#     end
#   end
#
#   let(:object_with_generator) { class_with_generator.new }
#
#   describe '#queue' do
#     subject(:queue) { object_with_generator.topic 'pizza_line', fifo: true }
#
#     it { is_expected.to be_a CycloneLariat::Resources::Topic }
#
#     it 'should match expected values' do
#       expect(queue.instance).to be 'test'
#       expect(queue.kind).to be :event
#       expect(queue.fifo).to be true
#       expect(queue.account_id).to eq 'account_id'
#       expect(queue.publisher).to eq 'pizzeria'
#       expect(queue.type).to eq 'pizza_line'
#       expect(queue.fifo).to eq true
#       expect(queue.tags).to eq({
#         dest: 'undefined',
#         fifo: 'true',
#         instance: 'test',
#         kind: 'event',
#         publisher: 'pizzeria',
#         type: 'pizza_line'
#       })
#     end
#   end
#
#   describe '#custom_queue' do
#
#   end
# end
