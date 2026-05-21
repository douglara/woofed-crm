require 'rails_helper'

RSpec.describe 'McpController authentication boundary', type: :request do
  let!(:account) { create(:account) }
  let!(:user)    { create(:user, account: account) }

  describe 'POST /mcp without an Authorization header' do
    it 'returns 401 with a WWW-Authenticate header that points to the protected-resource metadata' do
      post '/mcp',
           params:  { jsonrpc: '2.0', id: 0, method: 'initialize' }.to_json,
           headers: { 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['WWW-Authenticate']).to include('Bearer')
      expect(response.headers['WWW-Authenticate']).to include('resource_metadata="')
      expect(response.headers['WWW-Authenticate']).to include('/.well-known/oauth-protected-resource')
    end
  end

  describe 'POST /mcp with a token bound to a different resource' do
    it 'returns 401 invalid_token and still advertises the metadata pointer' do
      other_app = Doorkeeper::Application.create!(
        name: 'Other', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
        scopes: 'mcp', confidential: true
      )
      token = Doorkeeper::AccessToken.create!(
        application:       other_app,
        resource_owner_id: user.id,
        scopes:            'mcp',
        resource:          'https://elsewhere.example.com/api'
      )

      post '/mcp',
           params:  { jsonrpc: '2.0', id: 0, method: 'initialize' }.to_json,
           headers: { 'Authorization' => "Bearer #{token.token}", 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to include('error' => 'invalid_token')
      expect(response.headers['WWW-Authenticate']).to include('resource_metadata="')
    end
  end
end
