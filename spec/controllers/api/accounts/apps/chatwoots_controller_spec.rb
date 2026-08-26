require 'rails_helper'

RSpec.describe 'Chatwoot Inboxes API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:auth_headers) { { 'Authorization': "Bearer #{user.get_jwt_token}", 'Content-Type': 'application/json' } }

  describe 'GET /api/v1/accounts/:account_id/apps/chatwoots/inboxes' do
    let(:inboxes) do
      [{ 'id' => 46, 'name' => 'WhatsApp', 'channel_type' => 'Channel::Whatsapp',
         'message_templates' => [{ 'name' => 'lembrete_aula', 'language' => 'pt_BR' }] }]
    end
    let!(:chatwoot) { create(:apps_chatwoots, :skip_validate, account:, inboxes:) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/apps/chatwoots/inboxes"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it 'returns the synced inboxes with their templates' do
      get "/api/v1/accounts/#{account.id}/apps/chatwoots/inboxes", headers: auth_headers

      expect(response).to have_http_status(:ok)
      result = JSON.parse(response.body)
      inbox = result['inboxes'].first
      expect(inbox['name']).to eq('WhatsApp')
      expect(inbox['message_templates'].first['name']).to eq('lembrete_aula')
    end
  end
end
