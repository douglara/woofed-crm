# spec/jobs/apps/salesforce/connection/refresh_job_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Connection::RefreshJob do
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

  describe '#perform' do
    context 'when salesforce is connected' do
      let!(:salesforce) { create(:apps_salesforces, :connected) }

      it 'refreshes with the stored credentials and stores the new token' do
        stub_refresh

        described_class.perform_now

        expect(a_request(:post, token_url).with(body: hash_including(
          'grant_type' => 'refresh_token',
          'refresh_token' => 'refresh-token',
          'client_id' => 'consumer-key',
          'client_secret' => 'consumer-secret'
        ))).to have_been_made
        expect(salesforce.reload).to have_attributes(
          status: 'active',
          access_token: 'refreshed-access-token',
          refresh_token: 'refresh-token',
          token_expires_at: issued_at + Apps::Salesforce::TokenManagement::ASSUMED_SESSION_DURATION
        )
      end

      it 'refreshes even while the stored token is still valid, which is the point of the check' do
        stub_refresh

        described_class.perform_now

        expect(a_request(:post, token_url)).to have_been_made
        expect(salesforce.reload.access_token).to eq('refreshed-access-token')
      end

      context 'when the customer revoked the app on the salesforce side' do
        it 'flags the connection for reconnection' do
          stub_refresh(status: 400, body: { error: 'invalid_grant', error_description: 'expired access/refresh token' })

          described_class.perform_now

          expect(salesforce.reload.status).to eq('error')
        end
      end

      context 'when the org cannot be reached' do
        it 'leaves the connection active, since the failure is transient' do
          stub_request(:post, token_url).to_timeout

          described_class.perform_now

          expect(salesforce.reload.status).to eq('active')
        end
      end
    end

    context 'when the oauth flow was never completed' do
      let!(:salesforce) { create(:apps_salesforces) }

      it 'skips the connection' do
        described_class.perform_now

        expect(a_request(:post, token_url)).not_to have_been_made
        expect(salesforce.reload.status).to eq('inactive')
      end
    end

    context 'when the install has no salesforce connection' do
      it 'does nothing' do
        expect { described_class.perform_now }.not_to raise_error
      end
    end
  end
end
