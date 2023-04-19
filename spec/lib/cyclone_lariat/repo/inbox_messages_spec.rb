# frozen_string_literal: true

require 'cyclone_lariat/repo/inbox_messages'

RSpec.describe CycloneLariat::Repo::InboxMessages do
  let(:sequel_repo) { instance_double CycloneLariat::Repo::Sequel::InboxMessages }
  let(:sequel_repo_class) { class_double CycloneLariat::Repo::Sequel::InboxMessages, new: sequel_repo }

  let(:ar_repo) { instance_double CycloneLariat::Repo::ActiveRecord::InboxMessages }
  let(:ar_repo_class) { class_double CycloneLariat::Repo::ActiveRecord::InboxMessages, new: ar_repo }

  before do
    repo.dependencies = {
      sequel_messages_class: -> { sequel_repo_class },
      active_record_messages_class: -> { ar_repo_class }
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

  context 'when driver is active_record' do
    let(:repo) { described_class.new(driver: :active_record) }

    describe '#driver' do
      subject(:driver) { repo.driver }

      it 'is should be instance of ar repo' do
        is_expected.to eq(ar_repo)
      end
    end

    describe '#enabled?' do
      subject(:enabled?) { repo.enabled? }

      it 'should be delegated to ar repo' do
        expect(ar_repo).to receive(:enabled?)
        enabled?
      end
    end

    describe '#disabled?' do
      subject(:disabled?) { repo.disabled? }

      it 'should be delegated to ar repo' do
        expect(ar_repo).to receive(:disabled?)
        disabled?
      end
    end

    describe '#create' do
      subject(:create) { repo.create(42) }

      it 'should be delegated to ar repo' do
        expect(ar_repo).to receive(:create).with(42)
        create
      end
    end

    describe '#exists?' do
      subject(:exists?) { repo.exists?(uuid: 42) }

      it 'should be delegated to ar repo' do
        expect(ar_repo).to receive(:exists?).with(uuid: 42)
        exists?
      end
    end

    describe '#processed!' do
      subject(:processed!) { repo.processed!(uuid: 42) }

      it 'should be delegated to ar repo' do
        expect(ar_repo).to receive(:processed!).with(uuid: 42)
        processed!
      end
    end

    describe '#find' do
      subject(:find) { repo.find(uuid: 42) }

      it 'should be delegated to ar repo' do
        expect(ar_repo).to receive(:find).with(uuid: 42)
        find
      end
    end

    describe '#each_unprocessed' do
      subject(:each_unprocessed) { repo.each_unprocessed }

      it 'should be delegated to ar repo' do
        expect(ar_repo).to receive(:each_unprocessed)
        each_unprocessed
      end
    end

    describe '#each_with_client_errors' do
      subject(:each_with_client_errors) { repo.each_with_client_errors }

      it 'should be delegated to ar repo' do
        expect(ar_repo).to receive(:each_with_client_errors)
        each_with_client_errors
      end
    end
  end
end
