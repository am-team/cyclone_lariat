# frozen_string_literal: true

require 'cyclone_lariat/plugins/outbox'

RSpec.describe CycloneLariat::Outbox do
  let(:outbox) do
    described_class.new.tap do |instance|
      instance.dependencies = dependencies
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
  let(:on_sending_error) { nil }
  let(:repo)             { instance_double(CycloneLariat::Outbox::Repo::Messages, create: event.uuid, delete: true) }
  let(:sns_client)       { instance_double(CycloneLariat::Clients::Sns, publish: true) }
  let(:dependencies) do
    {
      sns_client: -> { sns_client },
      repo: -> { repo }
    }
  end

  before do
    CycloneLariat.configure { |config| config.driver = :sequel }
    CycloneLariat::Outbox.configure do |config|
      config.dataset = DB[:sequel_outbox_messages]
      config.resend_timeout = 120
      config.on_sending_error = on_sending_error
    end
    CycloneLariat::Outbox.load
  end

  after { CycloneLariat.configure { |config| config.driver = nil } }

  describe '#publish' do
    subject(:publish) { outbox.publish }

    before { outbox << event }

    it 'should publish messages' do
      publish
      expect(sns_client).to have_received(:publish).with(event, fifo: true)
    end

    it 'should delete sent messages' do
      publish
      expect(repo).to have_received(:delete).with([event.uuid])
    end

    context 'when sending message failed' do
      before do
        allow(sns_client).to receive(:publish).and_raise(StandardError.new('Something went wrong'))
        allow(repo).to receive(:update_error)
      end

      it 'should update message error' do
        publish
        expect(repo).to have_received(:update_error).with(event.uuid, 'Something went wrong')
      end

      it 'should not delete message' do
        publish
        expect(repo).not_to have_received(:delete).with([event.uuid])
      end

      context 'when on_sending_error callback present' do
        let(:on_sending_error) { double(call: true) }

        it 'should call on_sending_error' do
          publish
          expect(on_sending_error).to have_received(:call).with(event, instance_of(StandardError))
        end
      end
    end
  end

  describe '#push' do
    subject(:push) { outbox.push(event) }

    it 'should save to database' do
      push
      expect(repo).to have_received(:create).with(event)
    end

    it 'should save to messages array' do
      push
      expect(outbox.messages).to eq([event])
    end
  end
end
