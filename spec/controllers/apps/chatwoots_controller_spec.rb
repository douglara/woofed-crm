require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Apps::ChatwootsController, type: :request do
  describe 'POST /apps/chatwoots/webhooks' do
    context 'when chatwoot is inactive' do
      let!(:chatwoot) { create(:apps_chatwoots, :inactive, :skip_validate) }

      it 'does not process webhooks and returns unprocessable entity' do
        params = { token: chatwoot.embedding_token }

        expect(Accounts::Apps::Chatwoots::Webhooks::ProcessWebhookJob).not_to receive(:perform_later)
        post('/apps/chatwoots/webhooks', params:)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to include('Chatwoot is inactive')
      end
    end

    context 'when chatwoot is active' do
      let!(:chatwoot) { create(:apps_chatwoots, :skip_validate) }

      it 'processes webhooks successfully' do
        params = { token: chatwoot.embedding_token }

        expect(Accounts::Apps::Chatwoots::Webhooks::ProcessWebhookJob).to receive(:perform_later)
        post('/apps/chatwoots/webhooks', params:)
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)['ok']).to be_truthy
      end
    end

    context 'when chatwoot is not found' do
      it 'does not process webhooks and returns unprocessable entity' do
        params = { token: 'chatwoot_not_founded_token' }

        expect(Accounts::Apps::Chatwoots::Webhooks::ProcessWebhookJob).not_to receive(:perform_later)
        post('/apps/chatwoots/webhooks', params:)
        expect(response).to have_http_status(400)
        expect(response.body).to include('Unauthorized')
      end
    end
  end
end
