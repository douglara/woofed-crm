# spec/models/apps/salesforce/api/client_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Api::Client do
  let!(:salesforce) { create(:apps_salesforces, :connected) }
  let(:client) { described_class.new(salesforce) }
  let(:instance_url) { 'https://woofed-dev-ed.my.salesforce.com' }
  let(:path) { "#{instance_url}/services/data/v64.0/limits" }
  let(:token_url) { "#{instance_url}/services/oauth2/token" }

  describe '#get' do
    context 'when salesforce answers' do
      it 'sends the stored access token and returns the parsed body' do
        stub_request(:get, path).to_return(
          status: 200, body: { 'DailyApiRequests' => { 'Remaining' => 4200 } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        result = client.get(path)

        expect(a_request(:get, path).with(headers: { 'Authorization' => 'Bearer access-token' })).to have_been_made
        expect(result[:ok]).to eq('DailyApiRequests' => { 'Remaining' => 4200 })
      end
    end

    context 'when the session died before the estimated expiry' do
      it 'refreshes the token and replays the request once' do
        stub_request(:get, path)
          .to_return(status: 401, body: [{ errorCode: 'INVALID_SESSION_ID', message: 'Session expired' }].to_json)
          .then.to_return(status: 200, body: { 'records' => [] }.to_json)
        stub_request(:post, token_url).to_return(
          status: 200,
          body: { access_token: 'second-access-token', instance_url: instance_url,
                  id: 'https://login.salesforce.com/id/00D5g000000XXXXEA0/0055g00000ABCDEAA3' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        result = client.get(path)

        expect(result).to have_key(:ok)
        expect(a_request(:get, path).with(headers: { 'Authorization' => 'Bearer second-access-token' }))
          .to have_been_made
        expect(salesforce.reload.access_token).to eq('second-access-token')
      end

      it 'gives up when the refresh itself is rejected, and does not replay' do
        stub_request(:get, path).to_return(status: 401, body: [{ message: 'Session expired' }].to_json)
        stub_request(:post, token_url).to_return(status: 400, body: { error: 'invalid_grant' }.to_json)

        result = client.get(path)

        expect(result[:error]).to eq(I18n.t('apps.salesforce.oauth_errors.invalid_grant'))
        expect(a_request(:get, path)).to have_been_made.once
        expect(salesforce.reload.status).to eq('error')
      end
    end

    context 'when salesforce refuses the request' do
      it 'reports the messages it returned' do
        stub_request(:get, path).to_return(
          status: 400,
          body: [{ message: "No such column 'Foo' on entity 'Account'", errorCode: 'INVALID_FIELD' }].to_json
        )

        expect(client.get(path)[:error]).to eq("No such column 'Foo' on entity 'Account'")
      end

      it 'falls back to the status when the body carries no message' do
        stub_request(:get, path).to_return(status: 503, body: '<html>Service Unavailable</html>')

        expect(client.get(path)[:error]).to eq('HTTP 503')
      end
    end

    context 'when the org cannot be reached' do
      it 'reports it instead of raising' do
        stub_request(:get, path).to_timeout

        expect(client.get(path)[:error]).to eq(I18n.t('apps.salesforce.oauth_errors.connection_failed'))
      end
    end

    context 'when the stored credentials can no longer be decrypted' do
      it 'asks for a reconnection instead of calling salesforce' do
        allow(salesforce).to receive(:access_token).and_raise(ActiveRecord::Encryption::Errors::Decryption)

        result = client.get(path)

        expect(a_request(:get, path)).not_to have_been_made
        expect(result[:error]).to eq(I18n.t('apps.salesforce.oauth_errors.unreadable_credentials'))
        expect(salesforce.reload.status).to eq('error')
      end
    end
  end

  describe '#post' do
    it 'sends the body as json' do
      stub_request(:post, path).to_return(status: 200, body: { 'id' => '750Hn00000AbCdEIAV' }.to_json)

      result = client.post(path, operation: 'query')

      expect(a_request(:post, path).with(body: { operation: 'query' }.to_json)).to have_been_made
      expect(result[:ok]).to eq('id' => '750Hn00000AbCdEIAV')
    end
  end

  describe '#get_raw' do
    it 'hands the body over untouched, since bulk results are csv' do
      csv = "Id,Name\n001Hn00001AbCdEIAV,Acme\n"
      stub_request(:get, path).to_return(status: 200, body: csv, headers: { 'Sforce-Locator' => 'MTAwMDA' })

      result = client.get_raw(path)

      expect(result[:ok]).to eq(csv)
      expect(result[:request].headers['Sforce-Locator']).to eq('MTAwMDA')
    end
  end
end
