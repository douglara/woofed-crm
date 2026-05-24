require 'rails_helper'

RSpec.describe 'McpController authentication boundary', type: :request do
  let!(:account) { create(:account) }
  let!(:user)    { create(:user, account:) }

  describe 'POST /mcp without an Authorization header' do
    it 'returns 401 unauthorized' do
      post '/mcp',
           params: { jsonrpc: '2.0', id: 0, method: 'initialize' }.to_json,
           headers: { 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /mcp with a token bound to a different resource' do
    it 'returns 401 invalid_token and still advertises the metadata pointer' do
      other_app = Doorkeeper::Application.create!(
        name: 'Other', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
        scopes: 'mcp', confidential: true
      )
      token = Doorkeeper::AccessToken.create!(
        application: other_app,
        resource_owner_id: user.id,
        scopes: 'mcp',
        resource: 'https://elsewhere.example.com/api'
      )

      post '/mcp',
           params: { jsonrpc: '2.0', id: 0, method: 'initialize' }.to_json,
           headers: { 'Authorization' => "Bearer #{token.token}", 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to include('error' => 'invalid_token')
      expect(response.headers['WWW-Authenticate']).to include('resource_metadata="')
    end
  end

  describe 'POST /mcp with an expired doorkeeper token' do
    it 'returns 401 unauthorized' do
      expired_token = travel_to(9.hours.ago) do
        application = Doorkeeper::Application.find_or_create_by!(name: 'Spec Client') do |app|
          app.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
          app.scopes = 'mcp'
          app.confidential = true
        end
        Doorkeeper::AccessToken.create!(
          application:,
          resource_owner_id: user.id,
          scopes: 'mcp',
          resource: 'http://www.example.com/mcp',
          expires_in: Doorkeeper.config.access_token_expires_in
        ).token
      end

      post '/mcp',
           params: { jsonrpc: '2.0', id: 0, method: 'initialize' }.to_json,
           headers: { 'Authorization' => "Bearer #{expired_token}", 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
