require 'rails_helper'

RSpec.describe 'Deals API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:pipeline) { create(:pipeline, account:) }
  let!(:stage) { create(:stage, account:, pipeline:) }
  let!(:stage_2) { create(:stage, account:, pipeline:, name: 'Stage 2') }
  let!(:contact) { create(:contact, account:) }
  let(:deal) { create(:deal, account:, contact:, stage:) }
  let(:last_deal) { Deal.last }

  describe 'POST /api/v1/accounts/{account.id}/deals' do
    let(:valid_params) { { name: 'Deal 1', contact_id: contact.id, stage_id: stage.id } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/deals", params: valid_params }.not_to change(Deal, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'create deal and deal_opened event' do
        it do
          expect do
            post "/api/v1/accounts/#{account.id}/deals",
                 headers: { 'Authorization': "Bearer #{user.get_jwt_token}" },
                 params: valid_params
          end.to change(Deal, :count).by(1)
                                     .and change(Event, :count).by(1)

          expect(response).to have_http_status(:success)
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/deals/upsert' do
    let(:valid_params) { { name: 'Deal 1', contact_id: contact.id, stage_id: stage.id } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/deals/upsert", params: valid_params }.not_to change(Deal, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'create deal and deal_opened event' do
        it do
          expect do
            post "/api/v1/accounts/#{account.id}/deals/upsert",
                 headers: { 'Authorization': "Bearer #{user.get_jwt_token}" },
                 params: valid_params
          end.to change(Deal, :count).by(1)
                                     .and change(Event, :count).by(1)

          expect(response).to have_http_status(:success)
        end
      end

      context 'update deal' do
        let!(:deal) { create(:deal, account:, contact:, stage:, name: 'Old deal') }

        it 'update name' do
          expect do
            post "/api/v1/accounts/#{account.id}/deals/upsert",
                 headers: { 'Authorization': "Bearer #{user.get_jwt_token}" },
                 params: valid_params.except('stage_id')
          end.to change(Deal, :count).by(0)

          expect(response).to have_http_status(:success)
          expect(deal.reload.name).to eq('Deal 1')
        end

        it 'update stage' do
          expect do
            post "/api/v1/accounts/#{account.id}/deals/upsert",
                 headers: { 'Authorization': "Bearer #{user.get_jwt_token}" },
                 params: valid_params.except('name', 'stage_id').merge({ stage_id: stage_2.id })
          end.to change(Deal, :count).by(0)

          expect(response).to have_http_status(:success)
          expect(deal.reload.stage).to eq(stage_2)
        end
      end
    end
  end
  describe 'GET /api/v1/accounts/{account.id}/deals/{deal.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/deals/#{deal.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'get deal' do
        it 'should return deal' do
          get "/api/v1/accounts/#{account.id}/deals/#{deal.id}",
              headers: { 'Authorization': "Bearer #{user.get_jwt_token}" }

          expect(response).to have_http_status(:success)
          expect(response.body).to include(deal.name)
        end
      end
      context 'when deal is not found' do
        it 'should return not found' do
          get "/api/v1/accounts/#{account.id}/deals/69",
              headers: { 'Authorization': "Bearer #{user.get_jwt_token}" }

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
