# frozen_string_literal: true

require 'cyclone_lariat/plugins/outbox'

RSpec.describe CycloneLariat::Outbox::Repo::Messages do
  let(:repo) { described_class.new }
  let(:general_config) { CycloneLariat::Options.new(driver: driver_config) }

  let(:sequel_repo) { instance_double CycloneLariat::Outbox::Repo::Sequel::Messages }
  let(:sequel_repo_class) { class_double CycloneLariat::Outbox::Repo::Sequel::Messages, new: sequel_repo }

  let(:ar_repo) { instance_double CycloneLariat::Outbox::Repo::ActiveRecord::Messages }
  let(:ar_repo_class) { class_double CycloneLariat::Outbox::Repo::ActiveRecord::Messages, new: ar_repo }

  before do
    repo.dependencies = {
      sequel_messages_class: -> { sequel_repo_class },
      active_record_messages_class: -> { ar_repo_class },
      general_config: -> { general_config }
    }
  end

  context 'when driver undefined' do
    let(:driver_config) { nil }

    describe '#driver' do
      subject(:driver) { repo.driver }

      it { expect { driver }.to raise_error(ArgumentError) }
    end
  end

  context 'when driver is sequel' do
    let(:driver_config) { :sequel }

    describe '#driver' do
      subject(:driver) { repo.driver }

      it 'is should be instance of sequel repo' do
        is_expected.to eq(sequel_repo)
      end
    end

    describe '#create' do
      subject(:create) { repo.create(42) }

      it 'should be delegated to sequel repo' do
        expect(sequel_repo).to receive(:create).with(42)
        create
      end
    end

    describe '#delete' do
      subject(:delete) { repo.delete(42) }

      it 'should be delegated to sequel repo' do
        expect(sequel_repo).to receive(:delete).with(42)
        delete
      end
    end

    describe '#each_for_republishing' do
      subject(:each_for_republishing) { repo.each_for_republishing }

      it 'should be delegated to sequel repo' do
        expect(sequel_repo).to receive(:each_for_republishing)
        each_for_republishing
      end
    end

    describe '#update_error' do
      subject(:update_error) { repo.update_error(42, 'error_message') }

      it 'should be delegated to sequel repo' do
        expect(sequel_repo).to receive(:update_error).with(42, 'error_message')
        update_error
      end
    end
  end

  context 'when driver is active_record' do
    let(:driver_config) { :active_record }

    describe '#driver' do
      subject(:driver) { repo.driver }

      it 'is should be instance of ar repo' do
        is_expected.to eq(ar_repo)
      end
    end

    describe '#create' do
      subject(:create) { repo.create(42) }

      it 'should be delegated to sequel repo' do
        expect(ar_repo).to receive(:create).with(42)
        create
      end
    end

    describe '#delete' do
      subject(:delete) { repo.delete(42) }

      it 'should be delegated to sequel repo' do
        expect(ar_repo).to receive(:delete).with(42)
        delete
      end
    end

    describe '#each_for_republishing' do
      subject(:each_for_republishing) { repo.each_for_republishing }

      it 'should be delegated to sequel repo' do
        expect(ar_repo).to receive(:each_for_republishing)
        each_for_republishing
      end
    end

    describe '#update_error' do
      subject(:update_error) { repo.update_error(42, 'error_message') }

      it 'should be delegated to sequel repo' do
        expect(ar_repo).to receive(:update_error).with(42, 'error_message')
        update_error
      end
    end
  end
end
