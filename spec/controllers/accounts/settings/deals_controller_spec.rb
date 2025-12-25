require 'rails_helper'

RSpec.describe Accounts::Settings::DealsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }

  describe 'GET /accounts/{account.id}/settings/deals/edit' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/settings/deals/edit"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders edit page' do
        get "/accounts/#{account.id}/settings/deals/edit"
        expect(response).to have_http_status(:success)
      end
    end
  end
end
