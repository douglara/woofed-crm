require 'rails_helper'

RSpec.describe 'Deal Assignees API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:deal) { create(:deal) }
  let(:auth_headers) { { 'Authorization': "Bearer #{user.get_jwt_token}", 'Content-Type': 'application/json' } }

  describe 'DELETE /api/v1/accounts/{account.id}/deal_assignees/{deal_assignees.id}' do
    let!(:deal_assignee) do
      create(:deal_assignee, deal:, user:)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/deal_assignees/#{deal_assignee.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes the deal_assignee' do
        expect do
          delete "/api/v1/accounts/#{account.id}/deal_assignees/#{deal_assignee.id}", headers: auth_headers
        end.to change(DealAssignee, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end

      it 'returns not found if deal_assignee does not exist' do
        delete "/api/v1/accounts/#{account.id}/deal_assignees/xcdfdfkjgfdkbvkcj", headers: auth_headers

        expect(response).to have_http_status(:not_found)
        result = JSON.parse(response.body)
        expect(result['errors']).to eq('Deal assignee not found')
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/deal_assignees' do
    let(:valid_params) do
      { deal_id: deal.id, user_id: user.id }
    end

    let(:invalid_params) do
      { deal_id: nil, user_id: nil }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/deal_assignees", params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) { { deal_id: deal.id, user_id: user.id }.to_json }

      it 'creates a new deal_assignee' do
        expect do
          post "/api/v1/accounts/#{account.id}/deal_assignees", params:, headers: auth_headers
        end.to change(DealAssignee, :count).by(1)

        expect(response).to have_http_status(:created)
        result = JSON.parse(response.body)
        expect(result['deal_id']).to eq(deal.id)
        expect(result['user_id']).to eq(user.id)
      end

      context 'when params are invalid' do
        context 'with invalid user_id' do
          it 'returns unprocessable_entity with errors' do
            params = { deal_id: deal.id, user_id: 6565 }.to_json

            expect do
              post "/api/v1/accounts/#{account.id}/deal_assignees",
                   params:,
                   headers: auth_headers
            end.not_to change(DealAssignee, :count)

            expect(response).to have_http_status(:unprocessable_entity)
            result = JSON.parse(response.body)
            expect(result['errors']).to include(/User must exist/)
          end
        end

        context 'with invalid deal_id' do
          it 'returns unprocessable_entity with errors' do
            params = { deal_id: 6_546_516_216_546_564, user_id: user.id }.to_json

            expect do
              post "/api/v1/accounts/#{account.id}/deal_assignees",
                   params:,
                   headers: auth_headers
            end.not_to change(DealAssignee, :count)

            expect(response).to have_http_status(:unprocessable_entity)
            result = JSON.parse(response.body)
            expect(result['errors']).to include(/Deal must exist/)
          end
        end
      end
    end
  end
end
