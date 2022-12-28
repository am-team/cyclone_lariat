# frozen_string_literal: true

require 'cyclone_lariat/generators/command'
require 'cyclone_lariat/options'

RSpec.describe CycloneLariat::Generators::Command do
  let(:class_with_generator) do
    Class.new do
      include CycloneLariat::Generators::Command

      def config
        CycloneLariat::Options.new(
          publisher: 'pizzeria',
          version: 1
        )
      end
    end
  end

  let(:object_with_generator) { class_with_generator.new }

  describe '#command' do
    subject(:command) { object_with_generator.command 'create_pizza' }

    context 'version taken from config' do
      it 'should generate command version defined in config' do
        is_expected.to be_a CycloneLariat::Messages::V1::Command
      end
    end

    context 'version defined as `1`' do
      subject(:command) { object_with_generator.command 'create_pizza', version: 1 }

      it 'should generate V1 command' do
        is_expected.to be_a CycloneLariat::Messages::V1::Command
      end
    end

    context 'select undefined version' do
      subject(:command) { object_with_generator.command 'create_pizza', version: 42 }

      it { expect { command }.to raise_error ArgumentError }
    end
  end

  describe '#command_v1' do
    let(:uuid)       { SecureRandom.uuid }
    let(:request_id) { SecureRandom.uuid }

    subject(:command) do
      object_with_generator.command(
        'create_pizza',
        data: {
          type: 'margaritta',
          size: 'L'
        },
        request_id: request_id,
        uuid: uuid
      )
    end

    it { is_expected.to be_a CycloneLariat::Messages::V1::Command }

    it 'should be valid' do
      expect { command.validation.check! }.to_not raise_exception
    end

    it 'should match expected values' do
      expect(command.type).to eq('create_pizza')
      expect(command.data).to eq({ type: 'margaritta', size: 'L' })
      expect(command.request_id).to eq(request_id)
      expect(command.uuid).to eq(uuid)
      expect(command.kind).to eq('command')
      expect(command.version).to eq(1)
      expect(command.publisher).to eq('pizzeria')
    end
  end
end
