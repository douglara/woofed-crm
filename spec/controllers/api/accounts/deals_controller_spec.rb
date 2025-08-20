require 'rails_helper'

RSpec.describe 'Deals API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:pipeline) { create(:pipeline, account:) }
  let!(:stage) { create(:stage, account:, pipeline:) }
  let!(:contact) { create(:contact, account:) }
  let(:deal) { create(:deal, account:, contact:, stage:) }
  let(:last_deal) { Deal.last }
  let(:last_event) { Event.last }
  let(:last_deal_assignee) { DealAssignee.last }
  let(:auth_headers) { { 'Authorization': "Bearer #{user.get_jwt_token}", 'Content-Type': 'application/json' } }

  describe 'POST /api/v1/accounts/:account_id/deals' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect do
          post "/api/v1/accounts/#{account.id}/deals", params: {}
        end.to change(Deal, :count).by(0)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) { { name: 'Deal 1', contact_id: contact.id, stage_id: stage.id, pipeline_id: pipeline.id }.to_json }

      it 'creates deal, deal_opened event, and deal_assignee' do
        expect do
          post "/api/v1/accounts/#{account.id}/deals", params:, headers: auth_headers
        end.to change(Deal, :count).by(1)
                                    .and change(Event, :count).by(1)
                                                              .and change(DealAssignee, :count).by(1)
        expect(response).to have_http_status(:created)
        result = JSON.parse(response.body)
        expect(result['name']).to eq('Deal 1')
        expect(result['contact_id']).to eq(contact.id)
        expect(result['stage_id']).to eq(stage.id)
        expect(last_event.kind).to eq('deal_opened')
        expect(last_deal.creator).to eq(user)
        expect(last_deal_assignee.user).to eq(user)
        expect(last_deal_assignee.deal).to eq(last_deal)
      end

      context 'when params are invalid' do
        it 'returns unprocessable_entity with errors' do
          params = { name: 'Deal 1', contact_id: nil, stage_id: nil }.to_json

          expect do
            post "/api/v1/accounts/#{account.id}/deals", params:, headers: auth_headers
          end.to change(Deal, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['errors']).to include('Contact must exist', 'Stage must exist')
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/deals/upsert' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect do
          post "/api/v1/accounts/#{account.id}/deals/upsert", params: {}
        end.to change(Deal, :count).by(0)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) { { name: 'Deal 1', contact_id: contact.id, stage_id: stage.id, pipeline_id: pipeline.id }.to_json }

      it 'creates new deal and deal_opened event' do
        expect do
          post "/api/v1/accounts/#{account.id}/deals/upsert", params:, headers: auth_headers
        end.to change(Deal, :count).by(1)
                                    .and change(Event, :count).by(1)
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result['name']).to eq('Deal 1')
        expect(result['contact_id']).to eq(contact.id)
        expect(last_event.kind).to eq('deal_opened')
        expect(last_deal.account).to eq(account)
      end

      context 'when updating existing deal' do
        let!(:existing_deal) { create(:deal, account:, contact:, stage:, name: 'Old Deal') }

        it 'updates deal name' do
          params = { name: 'Updated Deal', contact_id: contact.id }.to_json
          expect do
            post "/api/v1/accounts/#{account.id}/deals/upsert", params:, headers: auth_headers
          end.to change(Deal, :count).by(0)
          expect(response).to have_http_status(:ok)
          expect(existing_deal.reload.name).to eq('Updated Deal')
        end
      end

      context 'when params are invalid' do
        it 'returns unprocessable_entity with errors' do
          params = { name: 'Deal 1', contact_id: nil, stage_id: nil }.to_json

          expect do
            post "/api/v1/accounts/#{account.id}/deals/upsert", params:, headers: auth_headers
          end.to change(Deal, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['errors']).to include('Contact must exist', 'Stage must exist')
        end
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/deals/:id' do
    let(:deal) { create(:deal, account:, contact:, stage:, pipeline:, name: 'Test Deal') }
    let!(:deal_assignee) { create(:deal_assignee, deal:, user:) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/deals/#{deal.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns deal with included contact, stage, and pipeline' do
        get "/api/v1/accounts/#{account.id}/deals/#{deal.id}", headers: auth_headers
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result['name']).to eq('Test Deal')
        expect(result['contact']['id']).to eq(contact.id)
        expect(result['stage']['id']).to eq(stage.id)
        expect(result['pipeline']['id']).to eq(pipeline.id)
        expect(result['deal_assignees']).not_to be_empty
        expect(result['deal_assignees'].first['deal_id']).to eq(deal.id)
        expect(result['deal_assignees'].first['user_id']).to eq(user.id)
      end

      context 'when deal is not found' do
        it 'returns not found' do
          get "/api/v1/accounts/#{account.id}/deals/9999", headers: auth_headers
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)).to eq({ 'errors' => 'Not found' })
        end
      end
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/deals/:id' do
    let!(:deal) { create(:deal, account:, contact:) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/deals/#{deal.id}", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) { { name: 'Deal Updated', status: 'open' }.to_json }

      it 'updates deal name' do
        patch "/api/v1/accounts/#{account.id}/deals/#{deal.id}", params:, headers: auth_headers
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result['name']).to eq('Deal Updated')
        expect(deal.reload.name).to eq('Deal Updated')
      end

      context 'when updating status to won' do
        it 'updates status and creates deal_won event' do
          params = { status: 'won' }.to_json
          expect do
            patch "/api/v1/accounts/#{account.id}/deals/#{deal.id}", params:, headers: auth_headers
          end.to change(Event, :count).by(1)
          expect(response).to have_http_status(:ok)
          expect(deal.reload.status).to eq('won')
          expect(last_event.kind).to eq('deal_won')
        end
      end

      context 'when updating status to lost' do
        it 'updates status and creates deal_lost event' do
          params = { status: 'lost' }.to_json
          expect do
            patch "/api/v1/accounts/#{account.id}/deals/#{deal.id}", params:, headers: auth_headers
          end.to change(Event, :count).by(1)
          expect(response).to have_http_status(:ok)
          expect(deal.reload.status).to eq('lost')
          expect(last_event.kind).to eq('deal_lost')
        end
      end

      context 'when deal is won and updated to open' do
        let!(:won_deal) { create(:deal, account:, stage:, contact:, status: 'won') }

        it 'updates status and creates deal_reopened event' do
          params = { status: 'open' }.to_json
          expect do
            patch "/api/v1/accounts/#{account.id}/deals/#{won_deal.id}", params:, headers: auth_headers
          end.to change(Event, :count).by(1)
          expect(response).to have_http_status(:ok)
          expect(won_deal.reload.status).to eq('open')
          expect(last_event.kind).to eq('deal_reopened')
        end
      end

      context 'when deal is not found' do
        it 'returns not found' do
          patch "/api/v1/accounts/#{account.id}/deals/9999", params:, headers: auth_headers
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)).to eq({ 'errors' => 'Not found' })
        end
      end

      context 'when params are invalid' do
        it 'returns unprocessable_entity with errors' do
          params = { stage_id: nil }.to_json

          patch "/api/v1/accounts/#{account.id}/deals/#{deal.id}", params:, headers: auth_headers
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['errors']).to include('Stage must exist')
        end
      end
    end
  end
end
