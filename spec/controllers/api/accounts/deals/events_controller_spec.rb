require 'rails_helper'

RSpec.describe 'Events API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:pipeline) { create(:pipeline, account: account) }
  let!(:stage) { create(:stage, account: account, pipeline: pipeline) }
  let!(:contact) { create(:contact, account: account) }
  let!(:deal) { create(:deal, account: account, contact: contact, stage: stage)}
  let(:last_event) { Event.last }

  describe 'POST /api/v1/accounts/{account.id}/deals/{deal.id}/events' do
    let(:valid_params) { { 'kind': 'activity', 'content': 'Test content', 'auto_done': true } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/deals/#{deal.id}/events", params: valid_params }.not_to change(Deal, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'create event' do
        it do
          expect do
            post "/api/v1/accounts/#{account.id}/deals/#{deal.id}/events",
            headers: {'Authorization': "Bearer #{user.get_jwt_token}"},
            params: valid_params
          end.to change(Event, :count).by(1)

          expect(response).to have_http_status(:success)
          expect(last_event.auto_done).to eq(true)
        end
      end
    end
  end
end
