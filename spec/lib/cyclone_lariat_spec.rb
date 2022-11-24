# frozen_string_literal: true

require_relative '../../lib/cyclone_lariat/options'

RSpec.describe CycloneLariat do
  # You should clone it for each test do reset do default state
  let(:cyclone_lariat) { described_class.clone }

  describe 'aws_key' do
    subject { cyclone_lariat.config.aws_key }

    context 'when it is defined' do
      before { cyclone_lariat.config.aws_key = 'foobar' }
      after  { cyclone_lariat.config.aws_key = nil }

      it 'should eq defined value' do
        is_expected.to eq 'foobar'
      end
    end

    context 'when it is not defined' do
      it { is_expected.to be_nil }
    end
  end

  describe 'aws_secret_key' do
    subject { cyclone_lariat.config.aws_secret_key }

    context 'when it is defined' do
      before { cyclone_lariat.config.aws_secret_key = 'foobar' }
      after  { cyclone_lariat.config.aws_secret_key = nil }

      it 'should eq defined value' do
        is_expected.to eq 'foobar'
      end
    end

    context 'when it is not defined' do
      it { is_expected.to be_nil }
    end
  end

  describe 'aws_account_id' do
    subject { cyclone_lariat.config.aws_account_id }

    context 'when it is defined' do
      before { cyclone_lariat.config.aws_account_id = 123 }
      after  { cyclone_lariat.config.aws_account_id = nil }

      it 'should eq defined value' do
        is_expected.to eq 123
      end
    end

    context 'when it is not defined' do
      it { is_expected.to be_nil }
    end
  end

  describe 'publisher' do
    subject { cyclone_lariat.config.publisher }

    context 'when it is defined' do
      before { cyclone_lariat.config.publisher = 'foobar' }
      after  { cyclone_lariat.config.publisher = nil }

      it 'should eq defined value' do
        is_expected.to eq 'foobar'
      end
    end

    context 'when it is not defined' do
      it { is_expected.to be_nil }
    end
  end

  describe 'aws_default_region' do
    subject { cyclone_lariat.config.aws_region }

    context 'when it is defined' do
      before { cyclone_lariat.config.aws_region = 'foobar' }
      after  { cyclone_lariat.config.aws_region = nil }

      it 'should eq defined value' do
        is_expected.to eq 'foobar'
      end
    end

    context 'when it is not defined' do
      it { is_expected.to be_nil }
    end
  end

  describe 'default_version' do
    subject { cyclone_lariat.config.version }

    context 'when it is defined' do
      before { cyclone_lariat.config.version = 2 }
      after  { cyclone_lariat.config.version = nil }

      it 'should eq defined value' do
        is_expected.to eq 2
      end
    end

    context 'when it is not defined' do
      it { is_expected.to be_nil }
    end
  end

  describe 'default_instance' do
    subject { cyclone_lariat.config.instance }

    context 'when it is defined' do
      before { cyclone_lariat.config.instance = :stage }
      after  { cyclone_lariat.config.instance = nil }

      it 'should eq defined value' do
        is_expected.to eq :stage
      end
    end

    context 'when it is not defined' do
      it { is_expected.to eq nil }
    end
  end
end
