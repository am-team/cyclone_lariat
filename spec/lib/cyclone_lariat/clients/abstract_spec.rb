# frozen_string_literal: true

require 'cyclone_lariat/clients/abstract'
require 'timecop'

RSpec.describe CycloneLariat::Clients::Abstract do
  let(:client) do
    described_class.new(aws_key: 'key', aws_secret_key: 'secret_key', aws_region: 'region', publisher: 'sample_app')
  end

  describe '.version' do
    subject(:version) { client.config.version }

    context 'when it does not defined' do
      it { is_expected.to be_nil }
    end

    context 'when it defined in config' do
      before { CycloneLariat.config.version = 13 }
      after  { CycloneLariat.config.version = 1 }

      it { is_expected.to eq 13 }
    end

    context 'when it is defined in class' do
      let(:abstract_client) { described_class.new }

      it 'sets dependency' do
        expect { abstract_client.config.version = 42 }.to change { abstract_client.config.version }.from(1).to 42
      end
    end
  end

  describe '.instance' do
    subject(:instance) { client.config.instance }

    context 'when it does not defined' do
      it { is_expected.to be_nil }
    end

    context 'when it defined in lariat config' do
      before { CycloneLariat.config.instance = :prod }
      after  { CycloneLariat.config.instance = :test }

      it { is_expected.to eq :prod }
    end

    context 'when it is defined in class' do
      let(:abstract_client) { described_class.new }

      it 'sets dependency' do
        expect { abstract_client.config.instance = :stage }.to change { abstract_client.config.instance }.from(:test).to :stage
      end
    end
  end

  describe '.publisher' do
    subject(:publisher) { client.config.publisher }

    let(:client) { described_class.new(aws_key: 'key', aws_secret_key: 'secret_key', aws_region: 'region') }

    context 'when it does not defined' do
      it { is_expected.to be_nil }
    end

    context 'when it defined in lariat config' do
      before { CycloneLariat.config.publisher = 'auth' }
      after  { CycloneLariat.config.publisher = nil }

      it { is_expected.to eq 'auth' }
    end

    context 'when it is defined in class' do
      let(:abstract_client) { described_class.new }

      it 'sets dependency' do
        expect { abstract_client.config.instance = 'stat' }.to change { abstract_client.config.instance }.from(:test).to 'stat'
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
        is_expected.to eq CycloneLariat::Messages::V1::Event.new(
          uuid: uuid,
          type: 'create_user',
          sent_at: event_sent_at,
          version: 1,
          publisher: 'sample_app',
          data: { mail: 'john.doe@mail.ru' }
        )
      end
    end

    context 'version is unknown' do
      subject(:event) do
        client.event(
          'create_user',
          data: { mail: 'john.doe@mail.ru' },
          uuid: SecureRandom.uuid,
          version: 12
        )
      end

      it 'should raise Argument error' do
        expect { event }.to raise_error ArgumentError
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
        is_expected.to eq CycloneLariat::Messages::V1::Command.new(
          uuid: uuid,
          type: 'create_user',
          sent_at: command_sent_at,
          version: 1,
          publisher: 'sample_app',
          data: { mail: 'john.doe@mail.ru' }
        )
      end
    end

    context 'version is unknown' do
      subject(:command) do
        client.command(
          'create_user',
          data: { mail: 'john.doe@mail.ru' },
          uuid: SecureRandom.uuid,
          version: 12
        )
      end

      it 'should build expected command with defined version' do
        expect { command }.to raise_error ArgumentError
      end
    end
  end
end
