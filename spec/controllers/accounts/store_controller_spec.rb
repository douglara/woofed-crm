require 'rails_helper'

RSpec.describe Accounts::StoresController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:store_base_url) { ENV.fetch('STORE_URL', 'https://store.woofedcrm.com') }

  describe 'GET /accounts/{account.id}/store' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/store"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'store home' do
        get "/accounts/#{account.id}/store"
        expect(response.body).to include('external-page-container')
        expect(response).to have_http_status(:success)
        expect(flash[:error]).to be_nil
      end

    it 'store with path' do
        get "/accounts/#{account.id}/store", params: { path: 'plugins/1' }
        expect(response.body).to include("#{store_base_url}/plugins/1")
        expect(response).to have_http_status(:success)
        expect(flash[:error]).to be_nil
      end
    end
  end
end
