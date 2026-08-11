require 'rails_helper'

RSpec.describe 'Accounts::Apps::SalesforcesController' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:credentials) do
    { apps_salesforce: { name: 'Salesforce', environment: 'production', client_id: 'consumer-key',
                         client_secret: 'consumer-secret' } }
  end

  before { sign_in user }

  describe 'POST /accounts/{account.id}/apps/salesforce' do
    context 'when the credentials are filled in' do
      it 'stores them and sends the user to the salesforce consent screen with PKCE' do
        expect do
          post account_apps_salesforce_path(account), params: credentials
        end.to change(Apps::Salesforce, :count).by(1)

        redirect = URI.parse(response.location)
        query = Rack::Utils.parse_query(redirect.query)

        expect("#{redirect.scheme}://#{redirect.host}#{redirect.path}")
          .to eq('https://login.salesforce.com/services/oauth2/authorize')
        expect(query).to include(
          'response_type' => 'code',
          'client_id' => 'consumer-key',
          'scope' => 'api refresh_token offline_access',
          'code_challenge_method' => 'S256',
          'redirect_uri' => apps_salesforces_oauth_callback_url
        )
        expect(query['code_challenge']).to be_present
        expect(query['state']).to be_present
      end
    end

    context 'when the org is a sandbox' do
      it 'authenticates against the test login host' do
        post account_apps_salesforce_path(account),
             params: credentials.deep_merge(apps_salesforce: { environment: 'sandbox' })

        expect(response.location).to start_with('https://test.salesforce.com/services/oauth2/authorize')
      end
    end

    context 'when a connection already exists' do
      it 'reconnects by editing it instead of creating a second one' do
        create(:apps_salesforces, client_id: 'old-consumer-key')

        expect do
          post account_apps_salesforce_path(account), params: credentials
        end.not_to change(Apps::Salesforce, :count)

        expect(Apps::Salesforce.first.client_id).to eq('consumer-key')
      end
    end

    context 'when the credentials are blank' do
      it 'redirects back with the error and stores nothing' do
        post account_apps_salesforce_path(account), params: { apps_salesforce: { client_id: '', client_secret: '' } }

        expect(response).to redirect_to(account_settings_path(account))
        expect(flash[:alert]).to be_present
        expect(Apps::Salesforce.count).to eq(0)
      end
    end
  end

  describe 'DELETE /accounts/{account.id}/apps/salesforce' do
    context 'when a connection exists' do
      it 'revokes the refresh token and removes it' do
        create(:apps_salesforces, :connected)
        revoke_url = 'https://woofed-dev-ed.my.salesforce.com/services/oauth2/revoke'
        stub_request(:post, revoke_url).to_return(status: 200)

        delete account_apps_salesforce_path(account)

        expect(a_request(:post, revoke_url)).to have_been_made
        expect(Apps::Salesforce.count).to eq(0)
        expect(response).to redirect_to(account_settings_path(account))
        expect(flash[:notice]).to eq(I18n.t('apps.salesforce.disconnected'))
      end
    end

    context 'when there is no connection' do
      it 'redirects back without failing' do
        delete account_apps_salesforce_path(account)

        expect(response).to redirect_to(account_settings_path(account))
      end
    end
  end
end
