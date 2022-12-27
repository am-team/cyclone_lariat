# frozen_string_literal: true

require 'cyclone_lariat/repo/versions'

RSpec.describe CycloneLariat::Repo::ActiveRecord::Versions do
  let(:dataset) { ArLariatVersion }
  let(:repo) { described_class.new dataset }

  describe '#add' do
    let(:version) { Time.now.to_i }
    subject(:add) { repo.add version }

    context 'when version does not exists' do
      it { is_expected.to be true }
    end

    context 'when version already exists' do
      before { repo.add(version) }
      it { expect { add }.to raise_error(ActiveRecord::RecordNotUnique) }
    end
  end

  describe '#remove' do
    let(:version) { Time.now.to_i }
    subject(:remove) { repo.remove version }

    context 'when version does not exists' do
      it { is_expected.to be false }
    end

    context 'when version already exists' do
      before { repo.add(version) }
      it { is_expected.to be true }
    end
  end

  describe '#all' do
    subject(:all) { repo.all }

    context 'when version does not exists' do
      it { is_expected.to eq [] }
    end

    context 'when version already exists' do
      let(:version) { Time.now.to_i }
      before { repo.add(version) }
      it { is_expected.to eq [{ version: version }] }
    end
  end
end
