require 'rails_helper'

RSpec.describe 'OAuth Dynamic Client Registration (RFC 7591)', type: :request do
  let(:json_headers) { { 'Content-Type' => 'application/json' } }
  let(:valid_payload) do
    { client_name: 'Claude', redirect_uris: ['https://claude.ai/api/mcp/auth_callback'] }
  end

  before { Rails.cache.clear }

  describe 'POST /oauth/register' do
    it 'creates a confidential Doorkeeper application and returns credentials with the default mcp scope' do
      expect do
        post '/oauth/register', params: valid_payload.to_json, headers: json_headers
      end.to change(Doorkeeper::Application, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      application = Doorkeeper::Application.last

      expect(body).to include(
        'client_id'     => application.uid,
        'client_secret' => application.plaintext_secret,
        'client_name'   => 'Claude',
        'redirect_uris' => ['https://claude.ai/api/mcp/auth_callback'],
        'grant_types'   => include('authorization_code', 'refresh_token'),
        'scope'         => 'mcp'
      )
      expect(application).to have_attributes(confidential: true, name: 'Claude')
    end

    it 'rejects non-JSON requests with 415 invalid_request' do
      post '/oauth/register', params: valid_payload.to_json,
                              headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }

      expect(response).to have_http_status(:unsupported_media_type)
      expect(JSON.parse(response.body)).to include('error' => 'invalid_request')
    end

    it 'rejects payload without redirect_uris with 400 invalid_redirect_uri' do
      post '/oauth/register', params: { client_name: 'No URIs' }.to_json, headers: json_headers

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to include('error' => 'invalid_redirect_uri')
    end

    it 'rate-limits to 10 registrations per IP per hour, returning 429 on the 11th attempt' do
      # Test env uses :null_store, which discards writes — the rate-limit code
      # path is only exercisable with a real cache. Swap locally and restore.
      previous_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      begin
        10.times do
          post '/oauth/register', params: valid_payload.to_json, headers: json_headers
          expect(response).to have_http_status(:created)
        end

        post '/oauth/register', params: valid_payload.to_json, headers: json_headers

        expect(response).to have_http_status(:too_many_requests)
        expect(JSON.parse(response.body)).to include('error' => 'rate_limited')
      ensure
        Rails.cache = previous_cache
      end
    end
  end
end
