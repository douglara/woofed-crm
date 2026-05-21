require 'rails_helper'

# End-to-end OAuth 2.1 flow: a Doorkeeper-issued JWT must travel through the
# same Mcp::JwtAuthenticator path that today's manually-issued tokens use.
RSpec.describe 'OAuth end-to-end flow', type: :request do
  let!(:account) { create(:account) }
  let!(:user)    { create(:user, account: account) }
  let(:redirect_uri) { 'https://claude.ai/api/mcp/auth_callback' }

  let(:code_verifier) { SecureRandom.urlsafe_base64(64).delete('=') }
  let(:code_challenge) do
    Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
  end

  let(:application) do
    Doorkeeper::Application.create!(
      name: 'Claude', redirect_uri: redirect_uri, scopes: 'mcp', confidential: true
    )
  end

  it 'exchanges an authorization code for a JWT that the MCP middleware accepts' do
    sign_in user

    get '/oauth/authorize', params: {
      client_id:             application.uid,
      redirect_uri:          redirect_uri,
      response_type:         'code',
      scope:                 'mcp',
      code_challenge:        code_challenge,
      code_challenge_method: 'S256',
      state:                 'xyz'
    }
    expect(response).to have_http_status(:ok)

    post '/oauth/authorize', params: {
      client_id:             application.uid,
      redirect_uri:          redirect_uri,
      response_type:         'code',
      scope:                 'mcp',
      code_challenge:        code_challenge,
      code_challenge_method: 'S256',
      state:                 'xyz'
    }
    expect(response).to have_http_status(:found)
    code = Rack::Utils.parse_query(URI.parse(response.location).query).fetch('code')

    post '/oauth/token', params: {
      grant_type:    'authorization_code',
      code:          code,
      redirect_uri:  redirect_uri,
      client_id:     application.uid,
      client_secret: application.plaintext_secret,
      code_verifier: code_verifier
    }
    expect(response).to have_http_status(:ok)
    token_body = JSON.parse(response.body)
    expect(token_body).to include('access_token', 'refresh_token', 'token_type' => 'Bearer')

    access_token = token_body['access_token']
    decoded = Users::JsonWebToken.decode_user(access_token)
    expect(decoded[:ok]).to eq(user)

    post '/mcp/messages',
         params:  { jsonrpc: '2.0', method: 'tools/list', id: 1 }.to_json,
         headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' }
    expect(response).not_to have_http_status(:unauthorized)
  end

  # Refresh rotation is rolling-with-grace: each /oauth/token call emits a fresh
  # refresh token, but the previous one stays usable until it expires
  # (refresh_token_expires_in in the doorkeeper initializer). The grace period
  # lets clients recover from network failures during refresh without a full
  # re-auth dance.
  it 'rotates the refresh token on each use, keeping the previous one valid during the grace window' do
    sign_in user

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
end
