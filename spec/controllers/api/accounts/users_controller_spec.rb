require 'rails_helper'

RSpec.describe 'Users API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:auth_headers) { { 'Authorization': "Bearer #{user.get_jwt_token}", 'Content-Type': 'application/json' } }

  describe 'GET /api/v1/accounts/{account.id}/users' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/users"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let!(:user2) { create(:user) }
      let!(:user3) { create(:user) }

      it 'returns all users' do
        get("/api/v1/accounts/#{account.id}/users", headers: auth_headers)
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result['data'].size).to eq(3)
        returned_ids = result['data'].map { |u| u['id'] }
        expect(returned_ids).to match_array([user.id, user2.id, user3.id])
      end
    end
  end
end
