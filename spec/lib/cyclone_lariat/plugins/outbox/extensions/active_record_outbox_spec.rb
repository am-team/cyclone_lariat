# frozen_string_literal: true

require 'cyclone_lariat/plugins/outbox'

RSpec.describe CycloneLariat::Outbox::Extensions::ActiveRecordOutbox do
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
    let(:outbox) { instance_double(CycloneLariat::Outbox, :<< => true, publish: true) }

    before do
      allow(CycloneLariat::Outbox).to receive(:new).and_return(outbox)
      CycloneLariat.configure { |config| config.driver = :active_record }
      CycloneLariat::Outbox.load
    end

    after { CycloneLariat.configure { |config| config.driver = nil } }

    it 'should publish outbox messages' do
      transaction
      expect(outbox).to have_received(:publish)
    end

    it 'should return transaction block result' do
      expect(transaction).to eq('result')
    end

    context 'when exception raised inside transaction' do
      subject(:transaction) do
        DB.transaction(with_outbox: true) do |outbox|
          outbox << event
          raise StandardError, 'Something went wrong'
        end
      end

      it 'should not publish outbox messages' do
        begin
          transaction
        rescue StandardError
          nil
        end
        expect(outbox).not_to have_received(:publish)
      end
    end
  end
end
