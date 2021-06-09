# frozen_string_literal: true

require_relative '../../lib/cyclone_lariat/errors'

RSpec.describe CycloneLariat::Errors::TopicNotFound do
  let(:error) { described_class.new(expected_topic: :topic_name) }

  it { expect(error).to be_a(LunaPark::Errors::System) }

  describe '#message' do
    subject(:error_message) { error.message }

    it 'should be eq expected message' do
      is_expected.to eq 'Could not found topic: `topic_name`'
    end
  end
end

RSpec.describe CycloneLariat::Errors::ClientError do
  let(:error) { described_class.new('Could not found user', email: 'john.doe@example.com') }

  it { expect(error).to be_a(LunaPark::Errors::Business) }

  describe '#message=' do
    context 'when defined new message' do
      before { error.message = 'New message' }

      it 'should be eq expected message' do
        expect(error.message).to eq 'New message'
      end
    end
  end

  describe '#details=' do
    context 'when defined new message' do
      before { error.details = { something: 'new' } }

      it 'should be eq expected message' do
        expect(error.details).to eq(something: 'new')
      end
    end
  end

  describe '==' do
    context 'when it compare with LunaPark business error' do
      let(:business_error) { LunaPark::Errors::Business.new('Could not found user', email: 'john.doe@example.com') }

      it 'should be equal' do
        expect(error == business_error).to eq true
      end
    end

    context 'when it compare with LunaPark system error' do
      let(:system_error) { LunaPark::Errors::System.new('Could not found user', email: 'john.doe@example.com') }

      it 'should not be equal' do
        expect(error == system_error).to eq false
      end
    end
  end
end
