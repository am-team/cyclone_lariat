# frozen_string_literal: true

require 'cyclone_lariat/plugins/outbox'

RSpec.describe CycloneLariat::Outbox::Extensions::ActiveRecordTransaction do
  describe '#transaction' do
    subject(:transaction) do
      ActiveRecord::Base.transaction(with_outbox: true) do |outbox|
        outbox << event
        'result'
      end
    end

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
    let(:messages_repo) { instance_double(CycloneLariat::Outbox::Repo::Messages, create: event.uuid, delete: true) }
    let(:sns_client)    { instance_double(CycloneLariat::Clients::Sns, publish: true) }

    before do
      CycloneLariat.configure { |config| config.driver = :active_record }
      CycloneLariat::Outbox.configure do |config|
        config.dataset = ArOutboxMessage
        config.republish_timeout = 120
      end
      allow(CycloneLariat::Clients::Sns).to receive(:new).and_return(sns_client)
      allow(CycloneLariat::Outbox::Repo::Messages).to receive(:new).and_return(messages_repo)
    end

    it 'should save outbox messages to database' do
      transaction
      expect(messages_repo).to have_received(:create).with(event)
    end

    it 'should publish outbox messages' do
      transaction
      expect(sns_client).to have_received(:publish).with(event, fifo: true)
    end

    it 'should delete published messages' do
      transaction
      expect(messages_repo).to have_received(:delete).with([event.uuid])
    end

    it 'should return transaction block result' do
      expect(transaction).to eq('result')
    end

    context 'when publishing of message fails' do
      before do
        allow(sns_client).to receive(:publish).and_raise(StandardError.new('Something went wrong'))
        allow(messages_repo).to receive(:update_error)
      end

      it 'should update message error' do
        transaction
        expect(messages_repo).to have_received(:update_error).with(event.uuid, 'Something went wrong')
      end

      it 'should not delete message' do
        transaction
        expect(messages_repo).not_to have_received(:delete).with([event.uuid])
      end
    end

    context 'when exception raised inside transaction' do
      subject(:transaction) do
        DB.transaction(with_outbox: true) do |outbox|
          outbox << event
          raise StandardError.new('Something went wrong')
        end
      end

      it 'should not publish outbox messages' do
        begin transaction rescue nil end
        expect(sns_client).not_to have_received(:publish).with(event)
      end
    end
  end
end
