# spec/models/apps/salesforce/connection/refresh_token_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Connection::RefreshToken do
  let(:token_url) { 'https://woofed-dev-ed.my.salesforce.com/services/oauth2/token' }
  let(:issued_at) { Time.zone.parse('2026-08-10 12:00:00 UTC') }
  let(:refreshed_response) do
    {
      access_token: 'refreshed-access-token',
      instance_url: 'https://woofed-dev-ed.my.salesforce.com',
      id: 'https://login.salesforce.com/id/00D5g000000XXXXEA0/0055g00000ABCDEAA3',
      issued_at: (issued_at.to_i * 1000).to_s,
      token_type: 'Bearer'
    }
  end

  def stub_refresh(status: 200, body: nil)
    stub_request(:post, token_url).to_return(
      status: status, body: (body || refreshed_response).to_json, headers: { 'Content-Type' => 'application/json' }
    )
  end

  describe '#call' do
    context 'when the stored token has expired' do
      let!(:salesforce) { create(:apps_salesforces, :connected, :token_expired) }

      it 'mints a new access token and keeps the refresh token the response does not return' do
        stub_refresh

        result = described_class.new(salesforce).call

        expect(a_request(:post, token_url).with(body: hash_including(
          'grant_type' => 'refresh_token', 'refresh_token' => 'refresh-token'
        ))).to have_been_made
        expect(result).to have_key(:ok)
        expect(salesforce.reload).to have_attributes(
          access_token: 'refreshed-access-token',
          refresh_token: 'refresh-token',
          status: 'active',
          token_expires_at: issued_at + Apps::Salesforce::TokenManagement::ASSUMED_SESSION_DURATION
        )
      end

      context 'when salesforce rejects the refresh token' do
        it 'flags the connection for reconnection' do
          stub_refresh(status: 400, body: { error: 'invalid_grant', error_description: 'expired access/refresh token' })

          result = described_class.new(salesforce).call

          expect(result[:error]).to eq(I18n.t('apps.salesforce.oauth_errors.invalid_grant'))
          expect(salesforce.reload.status).to eq('error')
        end
      end

      context 'when the org cannot be reached' do
        it 'leaves the connection alone, since the failure is transient' do
          stub_request(:post, token_url).to_timeout

          result = described_class.new(salesforce).call

          expect(result[:error]).to eq(I18n.t('apps.salesforce.oauth_errors.connection_failed'))
          expect(salesforce.reload.status).to eq('active')
        end
      end

      context 'when the answer does not come from salesforce, such as a proxy error page' do
        it 'reports it without blaming the connection' do
          stub_request(:post, token_url).to_return(status: 502, body: '<html>Bad Gateway</html>')

          result = described_class.new(salesforce).call

          expect(result[:error]).to eq(I18n.t('apps.salesforce.oauth_errors.unknown'))
          expect(salesforce.reload.status).to eq('active')
        end
      end
    end

    context 'when the stored token is still valid' do
      let!(:salesforce) { create(:apps_salesforces, :connected) }

      it 'does not spend a refresh, so a concurrent process does not lose its token' do
        result = described_class.new(salesforce).call

        expect(a_request(:post, token_url)).not_to have_been_made
        expect(result).to have_key(:ok)
        expect(salesforce.reload.access_token).to eq('access-token')
      end

      context 'when the refresh is forced' do
        it 'refreshes anyway, which is what a 401 retry needs' do
          stub_refresh

          described_class.new(salesforce, force: true).call

          expect(salesforce.reload.access_token).to eq('refreshed-access-token')
        end
      end
    end

    context 'when the connection has no refresh token' do
      let!(:salesforce) { create(:apps_salesforces) }

      it 'reports it instead of calling salesforce' do
        result = described_class.new(salesforce).call

        expect(a_request(:post, token_url)).not_to have_been_made
        expect(result[:error]).to eq(I18n.t('apps.salesforce.oauth_errors.missing_refresh_token'))
      end
    end
  end

  describe '#request' do
    let!(:salesforce) { create(:apps_salesforces, :connected) }

    it 'posts the refresh grant with the stored credentials to the org instance' do
      stub_refresh

      result = described_class.new(salesforce).send(:request)

      expect(a_request(:post, token_url).with(body: hash_including(
        'grant_type' => 'refresh_token',
        'refresh_token' => 'refresh-token',
        'client_id' => 'consumer-key',
        'client_secret' => 'consumer-secret'
      ))).to have_been_made
      expect(result).to have_key(:ok)
    end
  end

  describe '#handle' do
    let!(:salesforce) { create(:apps_salesforces, :connected) }

    context 'when salesforce refused the call' do
      it 'flags the connection as error and returns the result untouched' do
        result = { error: 'refused', code: 'invalid_grant' }

        expect(described_class.new(salesforce).send(:handle, result)).to eq(result)
        expect(salesforce.reload.status).to eq('error')
      end
    end

    context 'when the call failed without a salesforce code' do
      it 'keeps the current status' do
        result = { error: 'unreachable' }

        expect(described_class.new(salesforce).send(:handle, result)).to eq(result)
        expect(salesforce.reload.status).to eq('active')
      end
    end
  end
end
