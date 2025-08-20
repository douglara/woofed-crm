require 'rails_helper'

RSpec.describe 'Users API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:auth_headers) { { 'Authorization': "Bearer #{user.get_jwt_token}", 'Content-Type': 'application/json' } }

  describe 'POST /api/v1/accounts/{account.id}/users/search' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/users/search", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let!(:user2) { create(:user, full_name: 'John Doe') }
      let!(:user3) { create(:user) }
      let(:params) { { query: { full_name_cont: 'John Doe' } }.to_json }

      it 'returns matching users' do
        post("/api/v1/accounts/#{account.id}/users/search", params:, headers: auth_headers)
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result['pagination']['count']).to eq(1)
        expect(result['data'].size).to eq(1)
        expect(result['data'].first['full_name']).to eq(user2.full_name)
        expect(result['data'].first['email']).to eq(user2.email)
        expect(result['data'].first['phone']).to eq(user2.phone)
      end

      it 'returns no users when query does not match' do
        params = { query: { full_name_cont: 'User not found' } }.to_json

        post("/api/v1/accounts/#{account.id}/users/search", params:, headers: auth_headers)
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result['pagination']['count']).to eq(0)
        expect(result['data'].size).to eq(0)
        expect(result['data']).to be_empty
      end

      it 'return all users when query params is blank' do
        params = { query: {} }.to_json

        post("/api/v1/accounts/#{account.id}/users/search", params:, headers: auth_headers)
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result['data'].size).to eq(User.count)
      end

      context 'when params is invalid' do
        context 'when there is no ransack prefix to user params' do
          it 'should raise an error' do
            params = { query: { full_name: user.full_name, email: user.email } }.to_json

            post("/api/v1/accounts/#{account.id}/users/search",
                  headers: auth_headers,
                  params:)
            expect(response).to have_http_status(:unprocessable_entity)
            json = JSON.parse(response.body)
            expect(json['errors']).to eq('Invalid search parameters')
            expect(json['details']).to eq('No valid predicate for full_name')
          end
        end
      end
    end
  end
end
