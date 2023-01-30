# frozen_string_literal: true

require 'cyclone_lariat/core'

RSpec.describe CycloneLariat do
  let(:lariat) { described_class }

  describe '.config' do
    subject(:config) { lariat.config }

    it { is_expected.to be_a CycloneLariat::Options }
  end

  describe '.configure' do
    subject(:configure) do
      lariat.configure do |c|
        c.publisher = :test_publisher
      end
    end

    it 'should set options for CycloneLariat' do
      expect { configure }.to change { lariat.config.publisher }.from(nil).to(:test_publisher)
    end
  end
end
