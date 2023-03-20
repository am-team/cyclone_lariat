# frozen_string_literal: true

require 'cyclone_lariat/plugins/outbox'
require 'cyclone_lariat/plugins/outbox/services/republish'

RSpec.describe CycloneLariat::Outbox::Services::Republish do
  let(:call) do
    service = described_class.new
    service.dependencies = dependencies
    service.call
  end

  let(:messages_repo) { instance_double(CycloneLariat::Outbox::Repo::Messages) }
  let(:sns_client)    { instance_double(CycloneLariat::Clients::Sns) }
  let(:message1)       { CycloneLariat::Messages::V1::Event.new(uuid: SecureRandom.uuid, group_id: SecureRandom.uuid) }
  let(:message2)       { CycloneLariat::Messages::V1::Event.new(uuid: SecureRandom.uuid) }
  let(:dependencies) do
    {
      messages_repo: -> { messages_repo },
      sns_client: -> { sns_client }
    }
  end

  before do
    allow(messages_repo).to receive(:each_for_republishing).and_yield(message1).and_yield(message2)
    allow(messages_repo).to receive(:delete).and_return(true)
    allow(sns_client).to receive(:publish).and_return(true)
  end

  it 'publishes messages' do
    call
    expect(sns_client).to have_received(:publish).with(message1, fifo: true)
    expect(sns_client).to have_received(:publish).with(message2, fifo: false)
  end

  it 'deletes published messages' do
    call
    expect(messages_repo).to have_received(:delete).with([message1.uuid, message2.uuid])
  end

  context 'when publishing fails' do
    before do
      allow(sns_client).to receive(:publish).with(message2, fifo: false).and_raise(StandardError.new)
    end

    it 'does not delete unpublished messages' do
      call
      expect(messages_repo).to have_received(:delete).with([message1.uuid])
    end
  end
end
