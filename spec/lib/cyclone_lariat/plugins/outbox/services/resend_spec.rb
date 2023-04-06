# frozen_string_literal: true

require 'cyclone_lariat/plugins/outbox'
require 'cyclone_lariat/plugins/outbox/services/resend'

RSpec.describe CycloneLariat::Outbox::Services::Resend do
  let(:call) do
    service = described_class.new
    service.dependencies = dependencies
    service.call
  end

  let(:messages_repo)    { instance_double(CycloneLariat::Outbox::Repo::Messages) }
  let(:sns_client)       { instance_double(CycloneLariat::Clients::Sns) }
  let(:on_sending_error) { nil }
  let(:message1)         { CycloneLariat::Messages::V1::Event.new(uuid: SecureRandom.uuid, group_id: SecureRandom.uuid) }
  let(:message2)         { CycloneLariat::Messages::V1::Event.new(uuid: SecureRandom.uuid) }
  let(:dependencies) do
    {
      messages_repo: -> { messages_repo },
      sns_client: -> { sns_client },
      on_sending_error: -> { on_sending_error }
    }
  end

  before do
    allow(messages_repo).to receive(:transaction) { |&block| block.call }
    allow(messages_repo).to receive(:lock)
    allow(messages_repo).to receive(:each_with_error).and_yield(message1).and_yield(message2)
    allow(messages_repo).to receive(:delete).and_return(true)
    allow(messages_repo).to receive(:update_error).and_return(true)
    allow(sns_client).to receive(:publish).and_return(true)
  end

  it 'publishes messages' do
    call
    expect(sns_client).to have_received(:publish).with(message1, fifo: true)
    expect(sns_client).to have_received(:publish).with(message2, fifo: false)
  end

  it 'deletes sent messages' do
    call
    expect(messages_repo).to have_received(:delete).with(message1.uuid)
    expect(messages_repo).to have_received(:delete).with(message2.uuid)
  end

  context 'when sending message failed' do
    before do
      allow(sns_client).to receive(:publish).with(message2, fifo: false).and_raise(StandardError.new)
    end

    it 'should update message error' do
      call
      expect(messages_repo).to have_received(:update_error).with(message2.uuid, 'StandardError')
    end

    it 'does not delete messages' do
      call
      expect(messages_repo).to have_received(:delete).with(message1.uuid)
    end

    context 'when on_sending_error callback present' do
      let(:on_sending_error) { double(call: true) }

      it 'should call on_sending_error' do
        call
        expect(on_sending_error).to have_received(:call).with(message2, instance_of(StandardError))
      end
    end
  end
end
