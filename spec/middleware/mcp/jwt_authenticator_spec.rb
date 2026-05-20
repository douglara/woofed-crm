require 'rails_helper'

RSpec.describe 'MCP JWT authentication', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let(:jwt) { Users::JsonWebToken.encode_user(user) }
  let(:body) { { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json }

  context 'when unauthorized' do
    it 'rejects requests to /mcp/* without authorization header' do
      post '/mcp/messages', params: body, headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to include('error' => include('message' => 'Unauthorized'))
    end

    it 'rejects requests with an invalid JWT' do
      post '/mcp/messages', params: body,
                            headers: { 'Authorization' => 'Bearer not-a-valid-jwt',
                                       'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when authorized' do
    it 'forwards requests with a valid Bearer JWT to the MCP server' do
      post '/mcp/messages', params: body,
                            headers: { 'Authorization' => "Bearer #{jwt}",
                                       'Content-Type' => 'application/json' }
      expect(response).not_to have_http_status(:unauthorized)
    end

    it 'does not authenticate routes outside the /mcp prefix' do
      get '/up'
      expect(response).to have_http_status(:ok)
    end
  end
end
