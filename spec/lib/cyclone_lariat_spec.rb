require_relative '../../lib/cyclone_lariat/configure'

RSpec.describe CycloneLariat do
  # You should clone it for each test do reset do default state
  let(:cyclone_lariat) { described_class.clone }

  describe 'aws_key' do
    subject { cyclone_lariat.aws_key }

    context 'when it is defined' do
      before { cyclone_lariat.aws_key = 'foobar' }

      it 'should eq defined value' do
        is_expected.to eq 'foobar'
      end
    end

    context 'when it is not defined' do
      it { is_expected.to be_nil }
    end
  end

  describe 'aws_secret_key' do
    subject { cyclone_lariat.aws_secret_key }

    context 'when it is defined' do
      before { cyclone_lariat.aws_secret_key = 'foobar' }

      it 'should eq defined value' do
        is_expected.to eq 'foobar'
      end
    end

    context 'when it is not defined' do
      it { is_expected.to be_nil }
    end
  end

  describe 'aws_client_id' do
    subject { cyclone_lariat.aws_client_id }

    context 'when it is defined' do
      before { cyclone_lariat.aws_client_id = 123 }

      it 'should eq defined value' do
        is_expected.to eq 123
      end
    end

    context 'when it is not defined' do
      it { is_expected.to be_nil }
    end
  end

  describe 'publisher' do
    subject { cyclone_lariat.publisher }

    context 'when it is defined' do
      before { cyclone_lariat.publisher = 'foobar' }

      it 'should eq defined value' do
        is_expected.to eq 'foobar'
      end
    end

    context 'when it is not defined' do
      it { is_expected.to be_nil }
    end
  end

  describe 'aws_default_region' do
    subject { cyclone_lariat.aws_default_region }

    context 'when it is defined' do
      before { cyclone_lariat.aws_default_region = 'foobar' }

      it 'should eq defined value' do
        is_expected.to eq 'foobar'
      end
    end

    context 'when it is not defined' do
      it { is_expected.to be_nil }
    end
  end

  describe 'default_version' do
    subject { cyclone_lariat.default_version }

    context 'when it is defined' do
      before { cyclone_lariat.default_version = 2 }

      it 'should eq defined value' do
        is_expected.to eq 2
      end
    end

    context 'when it is not defined' do
      it { is_expected.to eq 1 }
    end
  end

  describe 'default_instance' do
    subject { cyclone_lariat.default_instance }

    context 'when it is defined' do
      before { cyclone_lariat.default_instance = :stage }

      it 'should eq defined value' do
        is_expected.to eq :stage
      end
    end

    context 'when it is not defined' do
      it { is_expected.to eq nil }
    end
  end
end
