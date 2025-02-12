# frozen_string_literal: true

require 'cyclone_lariat/generators/event'
require 'cyclone_lariat/options'

RSpec.describe CycloneLariat::Generators::Event do
  let(:class_with_generator) do
    Class.new do
      include CycloneLariat::Generators::Event

      def config
        CycloneLariat::Options.new(
          publisher: 'pizzeria',
          version: 1
        )
      end
    end
  end

  let(:object_with_generator) { class_with_generator.new }

  describe '#event' do
    subject(:event) { object_with_generator.event 'pizza_already_created' }

    context 'version taken from config' do
      it 'should generate event version defined in config' do
        is_expected.to be_a CycloneLariat::Messages::V1::Event
      end
    end

    context 'version defined as `1`' do
      subject(:event) { object_with_generator.event 'pizza_already_created', version: 1 }

      it 'should generate V1 event' do
        is_expected.to be_a CycloneLariat::Messages::V1::Event
      end
    end

    context 'version defined as `2`' do
      subject(:event) do
        object_with_generator.event 'pizza_already_created', version: 2,
                                                             subject: { type: 'pizzeria', uuid: SecureRandom.uuid },
                                                             object: { type: 'pizza', uuid: SecureRandom.uuid }
      end

      it 'should generate V2 event' do
        is_expected.to be_a CycloneLariat::Messages::V2::Event
      end
    end

    context 'select undefined version' do
      subject(:event) { object_with_generator.event 'pizza_already_created', version: 42 }

      it { expect { event }.to raise_error ArgumentError }
    end
  end

  describe '#event_v1' do
    let(:uuid)       { SecureRandom.uuid }
    let(:request_id) { SecureRandom.uuid }

    subject(:event) do
      object_with_generator.event_v1(
        'pizza_already_created',
        data: {
          type: 'margaritta',
          size: 'L'
        },
        request_id: request_id,
        uuid: uuid
      )
    end

    it { is_expected.to be_a CycloneLariat::Messages::V1::Event }

    it 'should be valid' do
      expect { event.validation.check! }.to_not raise_exception
    end

    it 'should match expected values' do
      expect(event.type).to eq('pizza_already_created')
      expect(event.data).to eq({ type: 'margaritta', size: 'L' })
      expect(event.request_id).to eq(request_id)
      expect(event.uuid).to eq(uuid)
      expect(event.kind).to eq('event')
      expect(event.version).to eq(1)
      expect(event.publisher).to eq('pizzeria')
    end
  end

  describe '#event_v2' do
    let(:uuid)        { SecureRandom.uuid }
    let(:request_id)  { SecureRandom.uuid }
    let(:subject_uid) { SecureRandom.uuid }
    let(:object_uid)  { SecureRandom.uuid }

    subject(:event) do
      object_with_generator.event_v2(
        'pizza_already_created',
        data: {
          type: 'margaritta',
          size: 'L'
        },
        subject: { type: 'pizzeria', uuid: subject_uid },
        object: { type: 'pizza', uuid: object_uid },
        request_id: request_id,
        uuid: uuid
      )
    end

    it { is_expected.to be_a CycloneLariat::Messages::V2::Event }

    it 'should be valid' do
      expect { event.validation.check! }.to_not raise_exception
    end

    it 'should match expected values' do
      expect(event.type).to eq('pizza_already_created')
      expect(event.data).to eq({ type: 'margaritta', size: 'L' })
      expect(event.request_id).to eq(request_id)
      expect(event.uuid).to eq(uuid)
      expect(event.subject).to eq(type: 'pizzeria', uuid: subject_uid)
      expect(event.object).to eq(type: 'pizza', uuid: object_uid)
      expect(event.kind).to eq('event')
      expect(event.version).to eq(2)
      expect(event.publisher).to eq('pizzeria')
    end
  end
end
