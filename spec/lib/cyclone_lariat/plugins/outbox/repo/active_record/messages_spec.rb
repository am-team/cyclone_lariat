# frozen_string_literal: true

require 'cyclone_lariat/plugins/outbox'

RSpec.describe CycloneLariat::Outbox::Repo::ActiveRecord::Messages do
  let(:dataset) { ArOutboxMessage }
  let(:resend_timeout) { 120 }
  let(:config) do
    CycloneLariat::Outbox.configure do |config|
      config.dataset = dataset
      config.resend_timeout = resend_timeout
    end
  end
  let(:repo) { described_class.new(config) }
  let(:event) do
    CycloneLariat::Messages::V1::Event.new(
      uuid: SecureRandom.uuid,
      publisher: 'users',
      type: 'create_user',
      version: 1,
      group_id: SecureRandom.uuid,
      deduplication_id: SecureRandom.uuid,
      data: { email: 'john.doe@example.com', password: 'password' },
      sending_error: 'Something went wrong'
    )
  end

  describe '#create' do
    subject(:create_event) { repo.create event }

    it 'should create event' do
      expect { create_event }.to change { dataset.count }.by(1)
    end

    it 'should create correct record' do
      created_event = dataset.find(create_event)
      expect(created_event[:uuid]).to be_a String
      expect(created_event[:group_id]).to eq event.group_id
      expect(created_event[:deduplication_id]).to eq event.deduplication_id
      expect(created_event[:sending_error]).to eq 'Something went wrong'
      expect(created_event[:serialized_message]).to eq event.to_json
    end

    context 'when event with same uuid is already exists' do
      before { repo.create event }

      it { expect { create_event }.to raise_error ActiveRecord::RecordNotUnique }
    end
  end

  describe '#each_for_resending' do
    let!(:event_within_timeout) { repo.create event }
    let!(:event_for_resending) do
      event = CycloneLariat::Messages::V1::Event.new(
        uuid: SecureRandom.uuid,
        publisher: 'users',
        type: 'create_user',
        version: 1,
        data: { email: 'john.doe@example.com', password: 'password' },
        sending_error: 'Something went wrong',
        sent_at: Time.now
      )
      uuid = repo.create event
      dataset.where(uuid: uuid).update(created_at: Time.now - resend_timeout)
      event
    end

    it 'should show only events available for resending' do
      expect { |b| repo.each_for_resending(&b) }.to yield_with_args(event_for_resending)
    end
  end

  describe '#delete' do
    subject(:delete_event) { repo.delete event_uuid }
    let!(:event_uuid) { repo.create event }

    it 'should delete event' do
      expect { delete_event }.to change { dataset.count }.by(-1)
    end
  end

  describe '#update_error' do
    subject(:update_error) { repo.update_error(event_uuid, 'Error message') }
    let!(:event_uuid) { repo.create event }

    it 'should update event sending error' do
      update_error
      expect(dataset.find(event_uuid)[:sending_error]).to eq('Error message')
    end
  end
end
