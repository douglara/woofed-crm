require 'rails_helper'

RSpec.describe 'OAuth discovery metadata', type: :request do
  describe 'GET /.well-known/oauth-protected-resource' do
    it 'advertises the MCP endpoint as a protected resource pointing back to this host as the auth server' do
      get '/.well-known/oauth-protected-resource'

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['resource']).to end_with('/mcp')
      expect(body['authorization_servers']).to be_an(Array).and(be_present)
    end
  end

  describe 'GET /.well-known/oauth-authorization-server' do
    let(:body) { JSON.parse(response.body) }

    before { get '/.well-known/oauth-authorization-server' }

    it 'returns the full RFC 8414 metadata document with all OAuth endpoints and PKCE S256' do
      expect(response).to have_http_status(:ok)

      expect(body).to include(
        'issuer'                                => be_present,
        'authorization_endpoint'                => end_with('/oauth/authorize'),
        'token_endpoint'                        => end_with('/oauth/token'),
        'registration_endpoint'                 => end_with('/oauth/register'),
        'grant_types_supported'                 => include('authorization_code', 'refresh_token'),
        'response_types_supported'              => ['code'],
        'code_challenge_methods_supported'      => ['S256'],
        'token_endpoint_auth_methods_supported' => include('client_secret_basic'),
        'scopes_supported'                      => include('mcp')
      )
    end
  end

  describe 'GET /.well-known/openid-configuration' do
    it 'aliases the OAuth metadata so ChatGPT-style clients that probe OIDC discovery do not get a 404' do
      get '/.well-known/openid-configuration'

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include(
        'issuer'                 => be_present,
        'authorization_endpoint' => end_with('/oauth/authorize'),
        'token_endpoint'         => end_with('/oauth/token'),
        'registration_endpoint'  => end_with('/oauth/register')
      )
    end
  end
end
