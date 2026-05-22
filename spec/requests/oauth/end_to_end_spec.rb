require 'rails_helper'

# End-to-end OAuth 2.1 flow: authorize → token → /mcp. Verifies that an
# opaque Doorkeeper access token bound to the MCP resource is accepted by
# McpController#doorkeeper_authorize! and McpController#validate_token_audience!.
RSpec.describe 'OAuth end-to-end flow', type: :request do
  let!(:account) { create(:account) }
  let!(:user)    { create(:user, account: account) }
  let(:redirect_uri) { 'https://claude.ai/api/mcp/auth_callback' }
  let(:resource_url) { 'http://www.example.com/mcp' }

  let(:code_verifier) { SecureRandom.urlsafe_base64(64).delete('=') }
  let(:code_challenge) do
    Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
  end

  let(:application) do
    Doorkeeper::Application.create!(
      name: 'Claude', redirect_uri: redirect_uri, scopes: 'mcp', confidential: true
    )
  end

  context 'when no user is signed in' do
    # The resource_owner_authenticator block in config/initializers/doorkeeper.rb
    # falls back to `warden.authenticate!(scope: :user)` when there's no session,
    # which Devise catches and turns into a redirect to /users/sign_in.
    it 'redirects GET /oauth/authorize to the Devise sign-in screen' do
      get '/oauth/authorize', params: {
        client_id:             application.uid,
        redirect_uri:          redirect_uri,
        response_type:         'code',
        scope:                 'mcp',
        code_challenge:        code_challenge,
        code_challenge_method: 'S256',
        state:                 'xyz',
        resource:              resource_url
      }

      expect(response).to have_http_status(:found)
      expect(response.location).to end_with('/users/sign_in')
    end
  end

  context 'when the user is signed in' do
    before { sign_in user }

    it 'exchanges an authorization code for an opaque token that McpController accepts' do
      get '/oauth/authorize', params: {
        client_id:             application.uid,
        redirect_uri:          redirect_uri,
        response_type:         'code',
        scope:                 'mcp',
        code_challenge:        code_challenge,
        code_challenge_method: 'S256',
        state:                 'xyz',
        resource:              resource_url
      }
      expect(response).to have_http_status(:ok)

      post '/oauth/authorize', params: {
        client_id:             application.uid,
        redirect_uri:          redirect_uri,
        response_type:         'code',
        scope:                 'mcp',
        code_challenge:        code_challenge,
        code_challenge_method: 'S256',
        state:                 'xyz',
        resource:              resource_url
      }
      expect(response).to have_http_status(:found)
      code = Rack::Utils.parse_query(URI.parse(response.location).query).fetch('code')

      post '/oauth/token', params: {
        grant_type:    'authorization_code',
        code:          code,
        redirect_uri:  redirect_uri,
        client_id:     application.uid,
        client_secret: application.plaintext_secret,
        code_verifier: code_verifier,
        resource:      resource_url
      }
      expect(response).to have_http_status(:ok)
      token_body = JSON.parse(response.body)
      expect(token_body).to include('access_token', 'refresh_token', 'token_type' => 'Bearer')

      access_token = token_body['access_token']
      record = Doorkeeper::AccessToken.by_token(access_token)
      expect(record.resource_owner_id).to eq(user.id)
      expect(record.resource).to eq(resource_url)

      post '/mcp',
           params:  { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json,
           headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)
      expect(payload.dig('result', 'tools')).to be_an(Array).and(be_present)
    end

    it 'rotates the refresh token on each use, keeping the previous one valid during the grace window' do
      grant = Doorkeeper::AccessGrant.create!(
        application: application, resource_owner_id: user.id, scopes: 'mcp',
        redirect_uri: redirect_uri, expires_in: 600,
        code_challenge: code_challenge, code_challenge_method: 'S256'
      )

      post '/oauth/token', params: {
        grant_type:    'authorization_code',
        code:          grant.token,
        redirect_uri:  redirect_uri,
        client_id:     application.uid,
        client_secret: application.plaintext_secret,
        code_verifier: code_verifier
      }
      first_refresh = JSON.parse(response.body).fetch('refresh_token')

      post '/oauth/token', params: {
        grant_type:    'refresh_token',
        refresh_token: first_refresh,
        client_id:     application.uid,
        client_secret: application.plaintext_secret
      }
      expect(response).to have_http_status(:ok)
      second_refresh = JSON.parse(response.body).fetch('refresh_token')
      expect(second_refresh).not_to eq(first_refresh)

      post '/oauth/token', params: {
        grant_type:    'refresh_token',
        refresh_token: first_refresh,
        client_id:     application.uid,
        client_secret: application.plaintext_secret
      }
      expect(response).to have_http_status(:ok)
    end

    it 'carries the resource indicator from /oauth/authorize to the access token when the client omits it on /oauth/token' do
      # Reproduces the ChatGPT-style flow:
      #   1. GET /oauth/authorize?resource=... (consent screen renders)
      #   2. User clicks "Authorize" → POST /oauth/authorize from the consent form
      #   3. POST /oauth/token WITHOUT `resource` in params
      # The hidden field in the consent view must forward `resource` on the POST
      # so the grant captures it and doorkeeper auto-propagates it to the token.
      common_params = {
        client_id:             application.uid,
        redirect_uri:          redirect_uri,
        response_type:         'code',
        scope:                 'mcp',
        code_challenge:        code_challenge,
        code_challenge_method: 'S256',
        state:                 'xyz',
        resource:              resource_url
      }

      # Step 1: GET — renders the consent screen with resource in the query string
      get '/oauth/authorize', params: common_params
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(name="resource"))
      expect(response.body).to include(resource_url)

      # Step 2: POST consent — the form should re-send resource via the hidden field
      post '/oauth/authorize', params: common_params
      code = Rack::Utils.parse_query(URI.parse(response.location).query).fetch('code')

      post '/oauth/token', params: {
        grant_type:    'authorization_code',
        code:          code,
        redirect_uri:  redirect_uri,
        client_id:     application.uid,
        client_secret: application.plaintext_secret,
        code_verifier: code_verifier
        # NOTE: resource intentionally omitted, mirroring ChatGPT's behaviour.
      }
      expect(response).to have_http_status(:ok)
      access_token = JSON.parse(response.body).fetch('access_token')

      record = Doorkeeper::AccessToken.by_token(access_token)
      expect(record.resource).to eq(resource_url)

      post '/mcp',
           params:  { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json,
           headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:ok)
    end

    it 'rejects MCP requests carrying a token issued for a different resource' do
      other_app = Doorkeeper::Application.create!(
        name: 'Other', redirect_uri: redirect_uri, scopes: 'mcp', confidential: true
      )
      foreign_token = Doorkeeper::AccessToken.create!(
        application:       other_app,
        resource_owner_id: user.id,
        scopes:            'mcp',
        resource:          'https://other.example.com/api'
      )

      post '/mcp',
           params:  { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json,
           headers: { 'Authorization' => "Bearer #{foreign_token.token}", 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to include('error' => 'invalid_token')
    end
  end
end
