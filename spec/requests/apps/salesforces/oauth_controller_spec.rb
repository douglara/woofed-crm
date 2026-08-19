require 'rails_helper'

RSpec.describe 'Apps::Salesforces::OauthController' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:token_url) { 'https://login.salesforce.com/services/oauth2/token' }
  let(:issued_at) { Time.zone.parse('2026-08-10 12:00:00 UTC') }
  let(:token_response) do
    {
      access_token: 'new-access-token',
      refresh_token: 'new-refresh-token',
      instance_url: 'https://woofed-dev-ed.my.salesforce.com',
      id: 'https://login.salesforce.com/id/00D5g000000XXXXEA0/0055g00000ABCDEAA3',
      issued_at: (issued_at.to_i * 1000).to_s,
      token_type: 'Bearer'
    }
  end

  before { sign_in user }

  # Starts the flow through the real controller so the session carries the state
  # and the PKCE verifier that the callback is checked against.
  def start_flow
    post account_apps_salesforce_path(account),
         params: { apps_salesforce: { client_id: 'consumer-key', client_secret: 'consumer-secret' } }

    Rack::Utils.parse_query(URI.parse(response.headers['X-Inertia-Location']).query)['state']
  end

  def stub_token(status: 200, body: nil)
    stub_request(:post, token_url).to_return(
      status: status, body: (body || token_response).to_json, headers: { 'Content-Type' => 'application/json' }
    )
  end

  describe 'GET /apps/salesforces/oauth/callback' do
    context 'when salesforce returns an authorization code' do
      it 'exchanges it and stores the connection salesforce returned' do
        state = start_flow
        stub_token

        get apps_salesforces_oauth_callback_path, params: { code: 'authorization-code', state: state }

        expect(a_request(:post, token_url).with(body: hash_including(
          'grant_type' => 'authorization_code',
          'code' => 'authorization-code',
          'client_secret' => 'consumer-secret'
        ))).to have_been_made
        expect(Apps::Salesforce.first).to have_attributes(
          status: 'active',
          access_token: 'new-access-token',
          refresh_token: 'new-refresh-token',
          instance_url: 'https://woofed-dev-ed.my.salesforce.com',
          organization_id: '00D5g000000XXXXEA0',
          token_expires_at: issued_at + Apps::Salesforce::TokenManagement::ASSUMED_SESSION_DURATION
        )
        expect(response).to redirect_to(account_apps_salesforce_path(account))
        expect(flash[:notice]).to eq(I18n.t('apps.salesforce.connected'))
      end

      it 'proves the exchange with the verifier kept in the session, never sent in the redirect' do
        state = start_flow
        stub_token

        get apps_salesforces_oauth_callback_path, params: { code: 'authorization-code', state: state }

        expect(a_request(:post, token_url).with { |request|
          Rack::Utils.parse_query(request.body)['code_verifier'].present?
        }).to have_been_made
      end
    end

    context 'when the state was not started by this session' do
      it 'refuses the callback without exchanging anything' do
        start_flow

        get apps_salesforces_oauth_callback_path, params: { code: 'authorization-code', state: 'tampered-state' }

        expect(a_request(:post, token_url)).not_to have_been_made
        expect(Apps::Salesforce.first.status).to eq('inactive')
        expect(flash[:alert]).to eq(I18n.t('apps.salesforce.invalid_state'))
      end
    end

    context 'when the authorization is denied on the salesforce side' do
      it 'reports the reason' do
        start_flow

        get apps_salesforces_oauth_callback_path, params: { error: 'access_denied' }

        expect(flash[:alert]).to eq(I18n.t('apps.salesforce.oauth_errors.access_denied'))
        expect(Apps::Salesforce.first.status).to eq('inactive')
      end
    end

    context 'when the external client app registers a different callback url' do
      it 'names the url this install expects, which is what the user has to paste' do
        state = start_flow
        stub_token(status: 400, body: { error: 'redirect_uri_mismatch', error_description: 'redirect_uri must match' })

        get apps_salesforces_oauth_callback_path, params: { code: 'authorization-code', state: state }

        expect(flash[:alert]).to include(apps_salesforces_oauth_callback_url)
        expect(Apps::Salesforce.first.status).to eq('inactive')
      end
    end

    context 'when no connection was ever created' do
      it 'asks the user to start again' do
        get apps_salesforces_oauth_callback_path, params: { code: 'authorization-code', state: 'any-state' }

        expect(flash[:alert]).to eq(I18n.t('apps.salesforce.missing_connection'))
      end
    end
  end
end
