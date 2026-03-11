require 'rails_helper'

RSpec.describe Accounts::AdvancedFiltersController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }

  describe 'GET /accounts/{account.id}/advanced_filter' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/advanced_filter"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before { sign_in(user) }

      it 'returns advanced filters page' do
        get "/accounts/#{account.id}/advanced_filter", params: { model: 'deal' }
        expect(response).to have_http_status(:success)
      end

      context 'when model param is not provided' do
        it 'returns 422 with error message' do
          get "/accounts/#{account.id}/advanced_filter"
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('Invalid model')
        end
      end

      context 'when model param is deal' do
        it 'returns fields for Deal model' do
          get "/accounts/#{account.id}/advanced_filter", params: { model: 'deal' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include('deals')
        end
      end

      context 'when model param is contact' do
        it 'returns fields for Contact model' do
          get "/accounts/#{account.id}/advanced_filter", params: { model: 'contact' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include('contacts')
        end
      end

      context 'when model param is user' do
        it 'returns fields for User model' do
          get "/accounts/#{account.id}/advanced_filter", params: { model: 'user' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include('users')
        end
      end

      context 'when model param is product' do
        it 'returns fields for Product model' do
          get "/accounts/#{account.id}/advanced_filter", params: { model: 'product' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include('products')
        end
      end

      context 'when model param is invalid' do
        it 'returns 422 with error message' do
          get "/accounts/#{account.id}/advanced_filter", params: { model: 'nonexistent' }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('Invalid model')
        end
      end

      context 'when redirect_url param is provided' do
        it 'includes redirect_url in the response' do
          redirect_url = "/accounts/#{account.id}/pipelines"
          get "/accounts/#{account.id}/advanced_filter", params: { redirect_url:, model: 'deal' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include(redirect_url)
        end
      end
    end
  end
end
