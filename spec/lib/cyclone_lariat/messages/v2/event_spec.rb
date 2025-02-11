# frozen_string_literal: true

require 'cyclone_lariat/messages/v2/event'
require 'securerandom'

module CycloneLariat # rubocop:disable Metrics/ModuleLength
  RSpec.describe Messages::V2::Event do
    let(:params) do
      {
        uuid: SecureRandom.uuid,
        publisher: 'example_publisher',
        type: 'user_email_updated',
        version: 2,
        data: { email: 'john.doe@example.com' },
        sent_at: '1970-01-01 16:40:00 +01:00',
        subject: {
          type: 'User',
          uuid: user_uuid
        },
        object: {
          type: 'User',
          uuid: user_uuid
        }
      }
    end

    let(:user_uuid) { SecureRandom.uuid }

    let(:message_class) do
      Class.new(described_class) do
        include LunaPark::Extensions::Validatable
        validator Messages::V2::Validator
        def kind
          'message'
        end
      end
    end

    let(:message) { message_class.new params }

    describe '#uuid' do
      subject(:uuid) { message.uuid }

      context 'when it undefined' do
        before { params.delete :uuid }

        it { is_expected.to be_nil }

        it 'should be invalid' do
          expect(message.valid?).to eq false
        end
      end

      context 'when it defined with uuid' do
        let(:uuid) { SecureRandom.uuid }
        before { params[:uuid] = uuid }

        it { is_expected.to match(/^\h{8}-\h{4}-(\h{4})-\h{4}-\h{12}$/) }

        it 'should be valid' do
          expect(message.valid?).to eq true
        end
      end

      context 'when it defined with not uuid' do
        before { params[:uuid] = 'sample' }

        it { is_expected.to eq 'sample' }

        it 'should be valid' do
          expect { message.validation.check! }.to raise_error(CycloneLariat::Errors::InvalidMessage)
        end
      end
    end

    describe '#publisher' do
      subject(:publisher) { message.publisher }

      context 'when it undefined' do
        before { params.delete :publisher }

        it { is_expected.to be_nil }

        it 'should be invalid' do
          expect(message.valid?).to eq false
        end
      end

      context 'when it defined with publisher' do
        before { params[:publisher] = 'publisher' }

        it 'should be eq defined string' do
          is_expected.to eq 'publisher'
        end

        it 'should be valid' do
          expect(message.valid?).to eq true
        end
      end
    end

    describe '#version' do
      subject(:version) { message.version }

      context 'when it undefined' do
        before { params.delete :version }

        it { is_expected.to be_nil }

        it 'should be invalid' do
          expect(message.valid?).to eq false
        end
      end

      context 'when it defined with 2' do
        before { params[:version] = 2 }

        it 'should be eq 1' do
          is_expected.to eq 2
        end

        it 'should be valid' do
          expect(message.valid?).to eq true
        end
      end

      context 'when it defined with \'2\'' do
        before { params[:version] = '2' }

        it 'should be eq 2 (int)' do
          is_expected.to eq 2
        end

        it 'should be valid' do
          expect(message.valid?).to eq true
        end
      end

      context 'when it defined with 1' do
        before { params[:version] = 1 }

        it 'should be eq 2' do
          is_expected.to eq 1
        end

        it 'should be invalid' do
          expect(message.valid?).to eq false
        end
      end
    end

    describe '#data' do
      subject(:data) { message.data }

      context 'when it undefined' do
        before { params.delete :data }

        it { is_expected.to be_an Hash }
        it { is_expected.to be_empty }

        it 'should be invalid' do
          expect(message.valid?).to eq true
        end
      end

      context 'when it defined with data' do
        before { params[:data] = { email: 'foobar@example.com' } }

        it 'should be eq defined string' do
          is_expected.to eq({ email: 'foobar@example.com' })
        end

        it 'should be valid' do
          expect(message.valid?).to eq true
        end
      end

      context 'when it defined without hash' do
        before { params[:data] = 'string' }

        it 'should be eq defined string' do
          is_expected.to eq('string')
        end

        it 'should be valid' do
          expect(message.valid?).to eq false
        end
      end
    end

    describe '#request_id' do
      subject(:request_id) { message.request_id }

      context 'when it undefined' do
        before { params.delete :request_id }

        it { is_expected.to be_nil }

        it 'should be valid' do
          expect(message.valid?).to eq true
        end
      end

      context 'when it defined with request_id' do
        let(:uuid) { SecureRandom.uuid }

        before { params[:request_id] = uuid }

        it 'should be eq defined uuid' do
          is_expected.to eq uuid
        end

        it 'should be valid' do
          expect(message.valid?).to eq true
        end
      end

      context 'when is not in UUID format' do
        before { params[:request_id] = 'string' }

        it 'should be eq defined string' do
          is_expected.to eq 'string'
        end

        it 'should be invalid' do
          expect(message.valid?).to be true
        end
      end
    end

    describe '#sent_at' do
      subject(:sent_at) { message.sent_at }

      context 'when it undefined' do
        before { params.delete :sent_at }

        it { is_expected.to be_nil }

        it 'should be invalid' do
          expect(message.valid?).to eq false
        end
      end

      context 'when it defined with sent_at' do
        let(:timestamp) { Time.now }

        before { params[:sent_at] = timestamp }

        it 'should be eq defined timestamp' do
          is_expected.to eq timestamp
        end

        it 'should be valid' do
          expect(message.valid?).to eq true
        end
      end

      context 'when it defined in string format' do
        before { params[:sent_at] = '1970-01-01 04:20:00' }

        it 'should be converted to Time format' do
          is_expected.to eq Time.parse('1970-01-01 04:20:00')
        end

        it 'should be valid' do
          expect(message.valid?).to eq true
        end
      end
    end

    describe '#group_id' do
      subject(:group_id) { message.group_id }

      context 'when it undefined' do
        before { params.delete :group_id }

        it { is_expected.to be_nil }

        it 'should be valid' do
          expect(message.valid?).to eq true
        end

        it 'message should not marked for fifo resource' do
          expect(message.fifo?).to eq false
        end
      end

      context 'when it defined as false' do
        before { params.delete :group_id }

        it { is_expected.to be_nil }

        it 'should be valid' do
          expect(message.valid?).to eq true
        end

        it 'message should not marked for fifo resource' do
          expect(message.fifo?).to eq false
        end
      end

      context 'when it defined with group_id' do
        before { params[:group_id] = '42' }

        it 'should be eq defined string' do
          is_expected.to eq '42'
        end

        it 'should be valid' do
          expect(message.valid?).to eq true
        end

        it 'message should marked for fifo resource' do
          expect(message.fifo?).to eq true
        end
      end
    end

    describe '#subject' do
      subject(:subject) { message.subject }

      context 'when it undefined' do
        before { params.delete :subject }

        it { is_expected.to be_an Hash }
        it { is_expected.to be_empty }

        it 'should be invalid' do
          expect(message.valid?).to eq false
        end
      end

      context 'when it defined with valid data' do
        it 'should be valid' do
          expect(message.valid?).to eq true
        end
      end

      context 'when it defined with invalid data' do
        context 'when uuid is not uuid' do
          before { params[:subject] = { type: 'User', uuid: 'rere' } }

          it 'should be invalid' do
            expect(message.valid?).to eq false
          end
        end

        context 'when type is not a string' do
          before { params[:subject] = { type: 1, uuid: SecureRandom.uuid } }

          it 'should be invalid' do
            expect(message.valid?).to eq false
          end
        end
      end

      context 'when it defined without hash' do
        before { params[:subject] = 'string' }

        it 'should be eq defined string' do
          is_expected.to eq('string')
        end

        it 'should be valid' do
          expect(message.valid?).to eq false
        end
      end
    end

    describe '#object' do
      subject(:object) { message.object }

      context 'when it undefined' do
        before { params.delete :object }

        it { is_expected.to be_an Hash }
        it { is_expected.to be_empty }

        it 'should be invalid' do
          expect(message.valid?).to eq false
        end
      end

      context 'when it defined with valid data' do
        it 'should be valid' do
          expect(message.valid?).to eq true
        end
      end

      context 'when it defined with invalid data' do
        context 'when uuid is not uuid' do
          before { params[:object] = { type: 'User', uuid: 'rere' } }

          it 'should be invalid' do
            expect(message.valid?).to eq false
          end
        end

        context 'when type is not a string' do
          before { params[:object] = { type: 1, uuid: SecureRandom.uuid } }

          it 'should be invalid' do
            expect(message.valid?).to eq false
          end
        end
      end

      context 'when it defined without hash' do
        before { params[:object] = 'string' }

        it 'should be eq defined string' do
          is_expected.to eq('string')
        end

        it 'should be valid' do
          expect(message.valid?).to eq false
        end
      end
    end

    describe '#to_json' do
      subject(:to_json) { message.to_json }
      let(:uuid) { SecureRandom.uuid }
      before { params[:uuid] = uuid }

      it 'should be in expected format' do
        expected_json = {
          uuid: uuid,
          publisher: 'example_publisher',
          type: 'message_user_email_updated',
          version: 2,
          data: {
            email: 'john.doe@example.com'
          },
          sent_at: '1970-01-01T16:40:00.000+01:00',
          subject: {
            type: 'User',
            uuid: user_uuid
          },
          object: {
            type: 'User',
            uuid: user_uuid
          }
        }.to_json

        is_expected.to eq(expected_json)
      end
    end
  end
end
