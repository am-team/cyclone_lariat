# frozen_string_literal: true

require 'luna_park/notifiers/log'
require 'cyclone_lariat/messages/v1/event'
require 'cyclone_lariat/middleware'

RSpec.describe CycloneLariat::Middleware do
  describe '#call' do
    subject(:receive_event) do
      middleware.call(nil, 'create_message', nil, { MessageId: 12, Message: msg }) do
        business_logic.call
      end
    end

    let(:business_logic) { double(call: :result) }
    let(:msg) { '{"uuid":"fcc3644b-f42c-4068-9ef9-06ceaa62b44d","publisher":"pilot","type":"event_test","version":1,"data":{"foo":1}}' }
    let(:notifier) { instance_double(LunaPark::Notifiers::Log, error: nil, warning: nil) }

    context 'when message_notifier is defined' do
      let(:middleware) { described_class.new({ message_notifier: notifier, driver: :sequel }) }

      it 'should write INFO log message' do
        expect(notifier).to receive(:info).with(
          'Receive message',
          queue: 'create_message',
          message: {
            data: { foo: 1 },
            publisher: 'pilot',
            type: 'event_test',
            uuid: 'fcc3644b-f42c-4068-9ef9-06ceaa62b44d',
            version: 1
          }
        )

        receive_event
      end
    end

    context 'when errors_notifier is defined' do
      let(:middleware) { described_class.new({ errors_notifier: notifier, driver: :sequel }) }

      context 'no any one exception is handled' do
        it 'should not write log message' do
          expect(notifier).to_not receive(:post)
          receive_event
        end
      end

      context 'receive business error' do
        subject(:receive_event) do
          middleware.call(nil, 'create_message', nil, { MessageId: 12, Message: msg }) do
            raise LunaPark::Errors::Business
          end
        end

        it 'should write ERROR notify' do
          expect(notifier).to receive(:error)
          receive_event
        end

        it 'should not raise error' do
          expect { receive_event }.to_not raise_error
        end
      end

      context 'receive system error' do
        subject(:receive_event) do
          middleware.call(nil, 'create_message', nil, { MessageId: 12, Message: msg }) do
            raise LunaPark::Errors::System
          end
        end

        it 'should write ERROR notify and raise this error' do
          expect(notifier).to receive(:error)
          expect { receive_event }.to raise_error(LunaPark::Errors::System)
        end
      end

      context 'receive system exception' do
        subject(:receive_event) do
          middleware.call(nil, 'create_message', nil, { MessageId: 12, Message: msg }) do
            raise StandardError
          end
        end

        it 'should write ERROR notify and raise this error' do
          expect(notifier).to receive(:error)
          expect { receive_event }.to raise_error(StandardError)
        end
      end

      context 'receive bad JSON' do
        subject(:receive_event) do
          middleware.call(nil, 'create_message', nil, { MessageId: 12, Message: 'I`m bad JSON`' }) do
            true
          end
        end

        it 'should write ERROR notify' do
          expect(notifier).to receive(:error)
          receive_event
        end

        it 'should not raise error' do
          expect { receive_event }.to_not raise_error
        end
      end
    end

    context 'when messages_repo is defined' do
      let(:dataset) { double }
      let(:messages_repo) { instance_double CycloneLariat::Repo::InboxMessages, disabled?: false, find: event }
      let(:messages_repo_class) { class_double(CycloneLariat::Repo::InboxMessages, new: messages_repo) }
      let(:middleware) { described_class.new({ inbox_dataset: dataset, repo: messages_repo_class }) }
      let(:event) { instance_double CycloneLariat::Messages::V1::Event, processed?: true }

      context 'when event is already exists in dataset' do
        let(:messages_repo) { instance_double CycloneLariat::Repo::InboxMessages, find: event, disabled?: false }
        it { is_expected.to be true }
        it 'should not run business logic' do
          expect(business_logic).to_not receive(:call)
          receive_event
        end

        it 'should not event as processed' do
          expect(messages_repo).to_not receive(:processed!)
          receive_event
        end

        it 'should not crete new event in repository' do
          expect(messages_repo).to_not receive(:create)
          receive_event
        end
      end

      context 'when event does not exists in dataset' do
        let(:messages_repo) { instance_double CycloneLariat::Repo::InboxMessages, find: nil, create: nil, processed!: true, disabled?: false }

        it { is_expected.to be true }

        it 'should run business logic' do
          expect(business_logic).to receive(:call)
          receive_event
        end

        it 'should mark event as processed' do
          expect(messages_repo).to receive(:processed!)
          receive_event
        end

        it 'should not crete new event in repository' do
          expect(messages_repo).to receive(:create)
          receive_event
        end
      end

      context 'when before_save hook is defined' do
        let(:on_before_save) { double(call: true) }
        let(:messages_repo) { instance_double CycloneLariat::Repo::InboxMessages, disabled?: false, find: nil, create: nil, processed!: true }
        let(:middleware) { described_class.new({ inbox_dataset: dataset, repo: messages_repo_class, before_save: on_before_save }) }

        it 'should call the hook' do
          expect(on_before_save).to receive(:call)
          receive_event
        end
      end
    end

    context 'when dataset is not defined' do
      let(:middleware) { described_class.new({ inbox_dataset: nil, driver: :sequel }) }

      it { is_expected.to be :result }

      it 'should run business logic' do
        expect(business_logic).to receive(:call)
        receive_event
      end
    end

    context 'when dataset is defined in config' do
      before do
        CycloneLariat.configure do |cfg|
          cfg.inbox_dataset = DB[:sequel_inbox_messages]
          cfg.driver = :sequel
        end
      end

      after do
        CycloneLariat.configure do |cfg|
          cfg.inbox_dataset = nil
          cfg.driver = nil
        end
      end

      let(:middleware) { described_class.new({ inbox_dataset: nil }) }

      it { is_expected.to be true }

      it 'should run business logic' do
        expect(business_logic).to receive(:call)
        receive_event
      end
    end
  end
end
