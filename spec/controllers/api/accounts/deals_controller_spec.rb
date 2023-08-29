require 'rails_helper'

RSpec.describe 'Deals API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:pipeline) { create(:pipeline, account: account) }
  let!(:stage) { create(:stage, account: account, pipeline: pipeline) }
  let!(:stage_2) { create(:stage, account: account, pipeline: pipeline, name: 'Stage 2') }
  let!(:contact) { create(:contact, account: account) }

  describe 'POST /api/v1/accounts/{account.id}/deals' do
    let(:valid_params) { { name: 'Deal 1', contact_id: contact.id, stage_id: stage.id } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/deals", params: valid_params }.not_to change(Deal, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'create deal' do
        it do
          expect do
            post "/api/v1/accounts/#{account.id}/deals",
            headers: {'Authorization': "Bearer #{user.get_jwt_token}"},
            params: valid_params
          end.to change(Deal, :count).by(1)
  
          expect(response).to have_http_status(:success)
        end

        it 'create deal without stage' do
          expect do
            post "/api/v1/accounts/#{account.id}/deals",
            headers: {'Authorization': "Bearer #{user.get_jwt_token}"},
            params: valid_params.except('stage_id').merge({pipeline_id: pipeline.id})
          end.to change(Deal, :count).by(1)
  
          expect(response).to have_http_status(:success)
          expect(Deal.last.stage).to eq(stage)
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
      context 'create deal' do
        it do
          expect do
            post "/api/v1/accounts/#{account.id}/deals/upsert",
            headers: {'Authorization': "Bearer #{user.get_jwt_token}"},
            params: valid_params
          end.to change(Deal, :count).by(1)
  
          expect(response).to have_http_status(:success)
        end

        it 'create deal without stage' do
          expect do
            post "/api/v1/accounts/#{account.id}/deals/upsert",
            headers: {'Authorization': "Bearer #{user.get_jwt_token}"},
            params: valid_params.except('stage_id').merge({pipeline_id: pipeline.id})
          end.to change(Deal, :count).by(1)
  
          expect(response).to have_http_status(:success)
          expect(Deal.last.stage).to eq(stage)
        end
      end

      context 'update deal' do
        let!(:deal) { create(:deal, account: account, contact: contact, stage: stage, name: 'Old deal') }

        it 'update name' do
          expect do
            post "/api/v1/accounts/#{account.id}/deals/upsert",
            headers: {'Authorization': "Bearer #{user.get_jwt_token}"},
            params: valid_params.except('stage_id')
          end.to change(Deal, :count).by(0)
  
          expect(response).to have_http_status(:success)
          expect(deal.reload.name).to eq('Deal 1')
        end

        it 'update stage' do
          expect do
            post "/api/v1/accounts/#{account.id}/deals/upsert",
            headers: {'Authorization': "Bearer #{user.get_jwt_token}"},
            params: valid_params.except('name', 'stage_id').merge({ stage_id: stage_2.id })
          end.to change(Deal, :count).by(0)
  
          expect(response).to have_http_status(:success)
          expect(deal.reload.stage).to eq(stage_2)
        end
      end
    end
  end
end