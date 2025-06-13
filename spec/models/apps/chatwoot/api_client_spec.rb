# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Apps::Chatwoot::ApiClient, type: :model do
  let(:apps_chatwoot) { build(:apps_chatwoots, chatwoot_endpoint_url: 'https://chatwoot.com') }
  subject { described_class.new(apps_chatwoot) }
  let(:request_headers) { { 'Content-Type' => 'application/json' } }

  describe '#get_request' do
    let(:response_body) { { 'result' => 'success', 'data' => { 'id' => 1 } }.to_json }

    context 'when the request is successful' do
      before do
        stub_request(:get, 'https://chatwoot.com/api/v1/test')
          .with(query: { foo: 'bar' })
          .to_return(status: 200, body: response_body, headers: request_headers)
      end

      it 'returns parsed response with :ok key' do
        result = subject.get_request('/api/v1/test', { foo: 'bar' })
        expect(result[:ok]).to eq(JSON.parse(response_body))
        expect(result[:request].status).to eq(200)
      end
    end

    context 'when the request fails' do
      before do
        stub_request(:get, 'https://chatwoot.com/api/v1/test')
          .with(query: { foo: 'bar' })
          .to_return(status: 404, body: '{"error":"Not found"}', headers: request_headers)
      end

      it 'returns error with :error key' do
        result = subject.get_request('/api/v1/test', { foo: 'bar' })
        expect(result[:error]).to eq('{"error":"Not found"}')
        expect(result[:request].status).to eq(404)
      end
    end

    context 'when the response body is empty on error' do
      before do
        stub_request(:get, 'https://chatwoot.com/api/v1/test')
          .to_return(status: 500, body: '', headers: request_headers)
      end

      it 'returns empty string as error' do
        result = subject.get_request('/api/v1/test')
        expect(result[:error]).to eq('')
        expect(result[:request].status).to eq(500)
      end
    end
  end
end
