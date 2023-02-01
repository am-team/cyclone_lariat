# frozen_string_literal: true

require 'securerandom'
require 'cyclone_lariat/repo/messages'

RSpec.describe CycloneLariat::Repo::Sequel::Messages do
  let(:dataset) { DB[:sequel_async_messages] }
  let(:repo) { described_class.new dataset }
  let(:event) do
    CycloneLariat::Messages::V1::Event.new(
      uuid: SecureRandom.uuid,
      publisher: 'users',
      type: 'event_create_user',
      version: 1,
      data: { email: 'john.doe@example.com', password: 'password' },
      client_error: LunaPark::Errors::Business.new('Something went wrong', some: 'thing'),
      sent_at: Time.now,
      received_at: Time.now
    )
  end

  describe '#create' do
    subject(:create_event) { repo.create event }

    it 'should create event' do
      expect { create_event }.to change { dataset.count }.by(1)
    end

    it 'should create correct record' do
      created_event = dataset.first(uuid: create_event)
      expect(created_event[:uuid]).to be_a String
      expect(created_event[:publisher]).to eq 'users'
      expect(created_event[:type]).to eq 'event_create_user'
      expect(created_event[:client_error_details]).to eq JSON.generate(some: :thing)
      expect(created_event[:client_error_message]).to eq 'Something went wrong'
      expect(created_event[:version]).to eq 1
      expect(created_event[:data]).to eq JSON.generate(email: 'john.doe@example.com', password: 'password')
      expect(created_event[:sent_at]).to be_a Time
      expect(created_event[:received_at]).to be_a Time
      expect(created_event[:processed_at]).to eq nil
    end

    context 'when event with same uuid is already exists' do
      before { repo.create event }

      it { expect { create_event }.to raise_error Sequel::UniqueConstraintViolation }
    end
  end

  describe '#exists?' do
    subject(:event_exists?) { repo.exists? uuid: uuid }

    context 'when event with expected uuid is exists' do
      let(:uuid) { repo.create event }

      it { is_expected.to be true }
    end

    context 'when event with expected uuid is not exists' do
      let(:uuid) { SecureRandom.uuid }

      it { is_expected.to be false }
    end
  end

  describe '#processed!' do
    subject(:event_processed!) { repo.processed! uuid: uuid }

    context 'when event with expected uuid is exists and event does not has error' do
      let(:uuid) { repo.create event }
      let(:event) do
        CycloneLariat::Messages::V1::Event.new(
          uuid: SecureRandom.uuid,
          publisher: 'users',
          type: 'event_create_user',
          version: 1,
          data: { email: 'john.doe@example.com', password: 'password' },
          sent_at: Time.now
        )
      end

      it 'should not set error' do
        expect { event_processed! }.not_to(change { repo.find(uuid: uuid).client_error })
      end

      it 'should mark event as processed' do
        expect { event_processed! }.to(change { repo.find(uuid: uuid).processed_at }.from(nil).to(Time))
      end
    end

    context 'when event catch error on process' do
      subject(:event_processed!) { repo.processed! uuid: uuid, error: CycloneLariat::Errors::ClientError.new }
      let(:uuid) { repo.create event }
      let(:event) do
        CycloneLariat::Messages::V1::Event.new(
          uuid: SecureRandom.uuid,
          publisher: 'users',
          type: 'event_create_user',
          version: 1,
          data: { email: 'john.doe@example.com', password: 'password' },
          sent_at: Time.now
        )
      end

      it 'should set error' do
        expect { event_processed! }.to change { repo.find(uuid: uuid).client_error }.from(nil).to(CycloneLariat::Errors::ClientError)
      end

      it 'should mark event as processed' do
        expect { event_processed! }.to change { repo.find(uuid: uuid).processed_at }.from(nil).to(Time)
      end
    end

    context 'when event is not exists' do
      let(:uuid) { SecureRandom.uuid }

      it { is_expected.to be false }
    end
  end

  describe '#find' do
    subject(:found_event) { repo.find uuid: uuid }
    let(:uuid)            { repo.create event }

    context 'when event exists' do
      it 'should return existent event' do
        is_expected.to eq event
      end
    end

    context 'when event not exists' do
      let(:uuid) { SecureRandom.uuid }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when pg_json extension enabled' do
      before { DB.extension :pg_json }

      it 'should be expected event' do
        is_expected.to eq event
      end
    end
  end

  describe '#each_unprocessed' do
    let!(:unprocessed_event) { repo.find uuid: repo.create(event) }
    let!(:processed_event) do
      uuid = repo.create CycloneLariat::Messages::V1::Event.new(
        uuid: SecureRandom.uuid,
        publisher: 'users',
        type: 'event_create_user',
        version: 1,
        data: { email: 'john.doe@example.com', password: 'password' },
        client_error: LunaPark::Errors::Business.new('Something went wrong', some: :thing),
        sent_at: Time.now
      )

      repo.processed! uuid: uuid
    end

    it 'should show only unprocessed event' do
      expect { |b| repo.each_unprocessed(&b) }.to yield_with_args(unprocessed_event)
    end
  end

  describe '#each_with_client_errors' do
    let!(:unprocessed_event) { repo.find uuid: repo.create(event) }
    let!(:processed_event) do
      uuid = repo.create CycloneLariat::Messages::V1::Event.new(
        uuid: SecureRandom.uuid,
        publisher: 'users',
        type: 'event_create_user',
        version: 1,
        data: { email: 'john.doe@example.com', password: 'password' },
        sent_at: Time.now
      )

      repo.processed! uuid: uuid
      repo.find(uuid: uuid)
    end

    let!(:processed_event_with_error) do
      uuid = repo.create CycloneLariat::Messages::V1::Event.new(
        uuid: SecureRandom.uuid,
        publisher: 'users',
        type: 'event_create_user',
        version: 1,
        data: { email: 'john.doe@example.com', password: 'password' },
        client_error: LunaPark::Errors::Business.new('Something went wrong', some: :thing),
        sent_at: Time.now
      )

      repo.processed! uuid: uuid
      repo.find(uuid: uuid)
    end

    it 'should show only unprocessed event' do
      expect { |b| repo.each_with_client_errors(&b) }.to yield_with_args(processed_event_with_error)
    end
  end
end
