require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::EvolutionApi::Instance::Create, type: :request do
  describe '.call' do
    let(:account) { create(:account) }
    let(:evolution_api) { create(:apps_evolution_api, account: account) }
    let(:create_instance_response) do
      File.read('spec/integration/use_cases/accounts/apps/evolution_api/instance/create_response.json')
    end
    let(:create_instance_response_unauthorized) do
      {
        "status": 401,
        "error": "Unauthorized",
        "response": {
          "message": "Unauthorized"
        }
      }.to_json
    end

    describe 'success' do
      before do
        stub_request(:post, /instance/)
          .to_return(body: create_instance_response, status: 201, headers: { 'Content-Type' => 'application/json' })
      end
      it 'create instance' do
        result = described_class.call(evolution_api)
        expect(result.key?(:ok)).to eq(true)
      end
    end
    describe 'failed' do
      context 'when user is unauthorized' do
        before do
          stub_request(:post, /instance/)
            .to_return(body: create_instance_response_unauthorized, status: 401, headers: { 'Content-Type' => 'application/json' })
        end
        it 'should return error message' do
          result = described_class.call(evolution_api)
          expect(result.key?(:error)).to eq(true)
        end
      end
    end
  end
end
