# frozen_string_literal: true

require 'cyclone_lariat/repo/messages'

RSpec.describe CycloneLariat::Repo::Messages do
  context 'when driver undefined' do
    let(:repo) { described_class.new }

    describe '#driver' do
      subject(:driver) { repo.driver }

      it { expect { driver }.to raise_error(ArgumentError) }
    end
  end

  context 'when driver is sequel' do
    let(:sequel_repo) { instance_double CycloneLariat::Repo::Sequel::Messages }
    let(:sequel_repo_class) { class_double CycloneLariat::Repo::Sequel::Messages, new: sequel_repo }
    let(:repo) { described_class.new(driver: :sequel) }

    before do
      repo.dependencies = {
        sequel_messages_class: -> { sequel_repo_class }
      }
    end

    describe '#driver' do
      subject(:driver) { repo.driver }

      it 'is should be instance of sequel repo' do
        is_expected.to eq(sequel_repo)
      end
    end

    describe '#enabled?' do
      subject(:enabled?) { repo.enabled? }

      it 'should be delegated to sequel repo' do
        expect(sequel_repo).to receive(:enabled?)
        enabled?
      end
    end

    describe '#disabled?' do
      subject(:disabled?) { repo.disabled? }

      it 'should be delegated to sequel repo' do
        expect(sequel_repo).to receive(:disabled?)
        disabled?
      end
    end

    describe '#create' do
      subject(:create) { repo.create(42) }

      it 'should be delegated to sequel repo' do
        expect(sequel_repo).to receive(:create).with(42)
        create
      end
    end

    describe '#exists?' do
      subject(:exists?) { repo.exists?(uuid: 42) }

      it 'should be delegated to sequel repo' do
        expect(sequel_repo).to receive(:exists?).with(uuid: 42)
        exists?
      end
    end

    describe '#processed!' do
      subject(:processed!) { repo.processed!(uuid: 42) }

      it 'should be delegated to sequel repo' do
        expect(sequel_repo).to receive(:processed!).with(uuid: 42)
        processed!
      end
    end

    describe '#find' do
      subject(:find) { repo.find(uuid: 42) }

      it 'should be delegated to sequel repo' do
        expect(sequel_repo).to receive(:find).with(uuid: 42)
        find
      end
    end

    describe '#each_unprocessed' do
      subject(:each_unprocessed) { repo.each_unprocessed }

      it 'should be delegated to sequel repo' do
        expect(sequel_repo).to receive(:each_unprocessed)
        each_unprocessed
      end
    end

    describe '#each_with_client_errors' do
      subject(:each_with_client_errors) { repo.each_with_client_errors }

      it 'should be delegated to sequel repo' do
        expect(sequel_repo).to receive(:each_with_client_errors)
        each_with_client_errors
      end
    end
  end
end
