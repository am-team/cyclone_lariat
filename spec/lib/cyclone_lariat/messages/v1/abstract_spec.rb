# frozen_string_literal: true

require 'cyclone_lariat/messages/v1/abstract'
require 'securerandom'

module CycloneLariat
  RSpec.describe Messages::V1::Abstract do
    let(:params) do
      {
        uuid: SecureRandom.uuid,
        publisher: 'example_publisher',
        type: 'create_user',
        version: 1,
        data: { email: 'john.doe@example.com' },
        sent_at: '1970-01-01 16:40:00'
      }
    end

    # let(:message) { described_class.new params }
    let(:message) do
      Class.new(described_class) do
        include LunaPark::Extensions::Validatable
        validator Messages::V1::Validator
        def kind
          'message'
        end
      end.new params
    end

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

        it 'should be present in JSON' do
          allow(message).to receive(:kind).and_return(:message)
          json = message.to_json
          expect(JSON.parse(json)['uuid']).to eq uuid
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

      context 'when it defined with 1' do
        before { params[:version] = 1 }

        it 'should be eq 1' do
          is_expected.to eq 1
        end

        it 'should be valid' do
          expect(message.valid?).to eq true
        end
      end

      context 'when it defined with \'1\'' do
        before { params[:version] = '1' }

        it 'should be eq 1 (int)' do
          is_expected.to eq 1
        end

        it 'should be valid' do
          expect(message.valid?).to eq true
        end
      end

      context 'when it defined with 2' do
        before { params[:version] = 2 }

        it 'should be eq 2' do
          is_expected.to eq 2
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

      context 'when it defined in int UUID format' do
        before { params[:request_id] = 'string' }

        it 'should be eq defined string' do
          is_expected.to eq('string')
        end

        it 'should be invalid' do
          expect(message.valid?).to eq false
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
          expect(message.valid?).to eq false
        end
      end
    end
  end
end
