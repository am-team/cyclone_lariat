# frozen_string_literal: true

require 'cyclone_lariat/repo/versions'

RSpec.describe CycloneLariat::Repo::Versions do
  let(:sequel_repo) { instance_double CycloneLariat::Repo::Sequel::Versions }
  let(:sequel_repo_class) do
    class_double CycloneLariat::Repo::Sequel::Versions, new: sequel_repo
  end
  let(:ar_repo) { instance_double CycloneLariat::Repo::ActiveRecord::Versions }
  let(:ar_repo_class) do
    class_double CycloneLariat::Repo::ActiveRecord::Versions, new: ar_repo
  end

  before do
    repo.dependencies = {
      sequel_versions_class: -> { sequel_repo_class },
      active_record_versions_class: -> { ar_repo_class }
    }
  end

  context 'when driver undefined' do
    let(:repo) { described_class.new }

    describe '#driver' do
      subject(:driver) { repo.driver }

      it { expect { driver }.to raise_error(ArgumentError) }
    end
  end

  context 'when driver is sequel' do
    let(:repo) { described_class.new(driver: :sequel) }

    describe '#driver' do
      subject(:driver) { repo.driver }

      it 'is should be instance of sequel repo' do
        is_expected.to eq(sequel_repo)
      end
    end

    describe '#add' do
      subject(:add) { repo.add(42) }

      it 'should be delegated to sequel repo' do
        expect(sequel_repo).to receive(:add).with(42)
        add
      end
    end

    describe '#remove' do
      subject(:remove) { repo.remove(42) }

      it 'should be delegated to sequel repo' do
        expect(sequel_repo).to receive(:remove).with(42)
        remove
      end
    end

    describe '#all' do
      subject(:all) { repo.all }

      it 'should be delegated to sequel repo' do
        expect(sequel_repo).to receive(:all)
        all
      end
    end
  end

  context 'when driver is active_record' do
    let(:repo) { described_class.new(driver: :active_record) }

    describe '#driver' do
      subject(:driver) { repo.driver }

      it 'is should be instance of ar repo' do
        is_expected.to eq(ar_repo)
      end
    end

    describe '#add' do
      subject(:add) { repo.add(42) }

      it 'should be delegated to ar repo' do
        expect(ar_repo).to receive(:add).with(42)
        add
      end
    end

    describe '#remove' do
      subject(:remove) { repo.remove(42) }

      it 'should be delegated to ar repo' do
        expect(ar_repo).to receive(:remove).with(42)
        remove
      end
    end

    describe '#all' do
      subject(:all) { repo.all }

      it 'should be delegated to ar repo' do
        expect(ar_repo).to receive(:all)
        all
      end
    end
  end
end
