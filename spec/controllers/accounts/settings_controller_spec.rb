require 'rails_helper'

RSpec.describe Accounts::SettingsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }

  describe 'GET /accounts/{account.id}/settings' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/settings"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'accesses the settings page' do
        get "/accounts/#{account.id}/settings"
        expect(response).to have_http_status(:success)
        expect(flash[:error]).to be_nil
      end

      # Salesforce is an Inertia page. Turbo Drive swaps only the <body>, so it
      # would leave the React root unmounted and the page blank until a manual
      # reload -- the link has to fall back to a full browser navigation.
      it 'renders the Salesforce link opted out of Turbo' do
        get "/accounts/#{account.id}/settings"

        link = Nokogiri::HTML(response.body).at_css("a[href='#{account_apps_salesforce_path(account)}']")
        expect(link['data-turbo']).to eq('false')
      end
    end
  end
end
