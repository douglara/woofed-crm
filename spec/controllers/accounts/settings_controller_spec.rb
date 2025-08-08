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
    end
  end
end
