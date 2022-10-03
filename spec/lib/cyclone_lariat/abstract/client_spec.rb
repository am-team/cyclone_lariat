# frozen_string_literal: true

require_relative '../../../../lib/cyclone_lariat'
require 'timecop'

RSpec.describe CycloneLariat::Abstract::Client do
  let(:client) do
    described_class.new(key: 'key', secret_key: 'secret_key', region: 'region', publisher: 'sample_app')
  end

  describe '.version' do
    subject(:version) { client.version }

    context 'when it does not defined' do
      it { is_expected.to eq 1 }
    end

    context 'when it defined in config' do
      before { CycloneLariat.default_version = 13 }
      after  { CycloneLariat.default_version = 1 }

      it { is_expected.to eq 13 }
    end

    context 'when it is defined in class' do
      after { described_class.version 1 }

      it 'sets dependency' do
        expect { described_class.version(42) }.to change { described_class.version }.from(1).to 42
      end
    end
  end

  describe '.instance' do
    subject(:instance) { client.instance }

    context 'when it does not defined' do
      it 'should be defined' do
        expect { instance }.to raise_error RuntimeError, 'You should define instance'
      end
    end

    context 'when it defined in config' do
      before { CycloneLariat.default_instance = :test }
      after  { CycloneLariat.default_instance = nil }

      it { is_expected.to eq :test }
    end

    context 'when it is defined in class' do
      before { CycloneLariat.default_instance = :prod }

      after  do
        CycloneLariat.default_instance = nil
        described_class.instance nil
      end

      it 'sets dependency' do
        expect { described_class.instance(:stage) }.to change { described_class.instance }.from(:prod).to :stage
      end
    end
  end

  describe '.publisher' do
    subject(:publisher) { described_class.publisher }

    context 'when it does not defined' do
      it 'should be defined' do
        expect { publisher }.to raise_error RuntimeError, 'You should define publisher'
      end
    end

    context 'when it defined in config' do
      before { CycloneLariat.publisher = 'best_app'}
      after  { CycloneLariat.publisher = nil }

      it { is_expected.to eq 'best_app' }
    end

    context 'when it does defined' do
      before { described_class.publisher 'you_app' }

      it 'should be defined' do
        expect(publisher).to eq 'you_app'
      end
    end
  end

  describe '#event' do
    context 'version is not defined' do
      subject(:event) { client.event('create_user', data: { mail: 'john.doe@mail.ru' }, uuid: uuid) }
      let(:event_sent_at) { Time.local(2021) }
      let(:uuid) { SecureRandom.uuid }

      before { Timecop.freeze event_sent_at }
      after  { Timecop.return }

      it 'should build expected event' do
        is_expected.to eq CycloneLariat::Event.new(
          uuid: uuid,
          type: 'create_user',
          sent_at: event_sent_at,
          version: 1,
          publisher: 'sample_app',
          data: { mail: 'john.doe@mail.ru' }
        )
      end
    end

    context 'version is defined' do
      subject(:event) { client.event('create_user', data: { mail: 'john.doe@mail.ru' }, uuid: uuid, version: 12) }
      let(:event_sent_at) { Time.local(2021) }
      let(:uuid) { SecureRandom.uuid }

      before { Timecop.freeze event_sent_at }
      after  { Timecop.return }

      it 'should build expected event with defined version' do
        is_expected.to eq CycloneLariat::Event.new(
          uuid: uuid,
          type: 'create_user',
          sent_at: event_sent_at,
          version: 12,
          publisher: 'sample_app',
          data: { mail: 'john.doe@mail.ru' }
        )
      end
    end
  end

  describe '#command' do
    context 'version is not defined' do
      subject(:command) { client.command('create_user', data: { mail: 'john.doe@mail.ru' }, uuid: uuid) }
      let(:command_sent_at) { Time.local(2021) }
      let(:uuid) { SecureRandom.uuid }

      before { Timecop.freeze command_sent_at }
      after  { Timecop.return }

      it 'should build expected command' do
        is_expected.to eq CycloneLariat::Command.new(
          uuid: uuid,
          type: 'create_user',
          sent_at: command_sent_at,
          version: 1,
          publisher: 'sample_app',
          data: { mail: 'john.doe@mail.ru' }
        )
      end
    end

    context 'version is defined' do
      subject(:command) { client.command('create_user', data: { mail: 'john.doe@mail.ru' }, uuid: uuid, version: 12) }
      let(:command_sent_at) { Time.local(2021) }
      let(:uuid) { SecureRandom.uuid }

      before { Timecop.freeze command_sent_at }
      after  { Timecop.return }

      it 'should build expected command with defined version' do
        is_expected.to eq CycloneLariat::Command.new(
          uuid: uuid,
          type: 'create_user',
          sent_at: command_sent_at,
          version: 12,
          publisher: 'sample_app',
          data: { mail: 'john.doe@mail.ru' }
        )
      end
    end
  end
end
