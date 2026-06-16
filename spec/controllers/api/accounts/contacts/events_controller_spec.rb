require 'rails_helper'

RSpec.describe 'Contact Events API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:contact) { create(:contact) }
  let(:last_event) { Event.last }
  let(:auth_headers) { { 'Authorization': "Bearer #{user.get_jwt_token}", 'Content-Type': 'application/json' } }

  describe 'POST /api/v1/accounts/:account_id/contacts/:contact_id/events' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect do
          post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/events", params: {}
        end.to change(Event, :count).by(0)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it 'creates a note event on the contact without requiring a deal' do
      params = { kind: 'note', content: 'Called the lead' }.to_json

      expect do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/events", params:, headers: auth_headers
      end.to change(Event, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(last_event.contact).to eq(contact)
      expect(last_event.from_me).to be true
      expect(last_event.kind).to eq('note')
    end

    it 'creates a scheduled chatwoot_message carrying the template attributes' do
      chatwoot = create(:apps_chatwoots, :skip_validate, account:,
                                                         inboxes: [{ 'id' => 46, 'channel_type' => 'Channel::Whatsapp',
                                                                     'message_templates' => [{ 'name' => 'lembrete_aula', 'language' => 'pt_BR', 'category' => 'UTILITY',
                                                                                               'components' => [{ 'type' => 'BODY', 'text' => 'Oi {{1}} {{2}}' }] }] }])
      params = { kind: 'chatwoot_message', app_type: 'Apps::Chatwoot', app_id: chatwoot.id, scheduled_at: 1.hour.from_now,
                 additional_attributes: { chatwoot_inbox_id: '46', chatwoot_template_name: 'lembrete_aula',
                                          template_body_params: { '1' => 'Paula', '2' => '14:00' } } }.to_json

      expect do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/events", params:, headers: auth_headers
      end.to change(Event, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(last_event.additional_attributes['chatwoot_template_name']).to eq('lembrete_aula')
      expect(last_event.additional_attributes['template_body_params']).to eq('1' => 'Paula', '2' => '14:00')
    end

    it 'returns unprocessable_entity for invalid params' do
      params = { kind: nil }.to_json

      expect do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/events", params:, headers: auth_headers
      end.to change(Event, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
