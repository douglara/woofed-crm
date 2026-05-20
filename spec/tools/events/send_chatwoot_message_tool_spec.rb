require 'rails_helper'

RSpec.describe 'MCP tool: events_send_chatwoot_message', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:contact) { create(:contact) }
  let!(:deal) { create(:deal, contact: contact) }
  let!(:chatwoot_app) { create(:apps_chatwoots, :skip_validate) }
  let(:auth_headers) do
    { 'Authorization' => "Bearer #{Users::JsonWebToken.encode_user(user)}",
      'Content-Type' => 'application/json' }
  end
  let(:last_event) { Event.last }
  let(:scheduled_at) { 1.day.from_now.utc.iso8601 }
  let(:base_arguments) do
    { deal_id: deal.id, content: 'How are you?',
      app_id: chatwoot_app.id, chatwoot_inbox_id: '62483' }
  end

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      expect do
        post '/mcp/messages',
             params: mcp_tool_call_body('events_send_chatwoot_message',
                                         base_arguments.merge(scheduled_at: scheduled_at)),
             headers: { 'Content-Type' => 'application/json' }
      end.not_to change(Event, :count)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'schedules a Chatwoot message at scheduled_at' do
      expect do
        post '/mcp/messages',
             params: mcp_tool_call_body('events_send_chatwoot_message',
                                         base_arguments.merge(scheduled_at: scheduled_at)),
             headers: auth_headers
      end.to change(Event, :count).by(1)
      expect(last_event).to have_attributes(
        kind: 'chatwoot_message', title: 'Chatwoot Message',
        app_type: 'Apps::Chatwoot', app_id: chatwoot_app.id,
        scheduled_at: Time.parse(scheduled_at), auto_done: true
      )
      expect(last_event.additional_attributes).to include('chatwoot_inbox_id' => '62483')
    end

    it 'returns an error when neither deal_id nor contact_id is provided' do
      expect do
        post '/mcp/messages',
             params: mcp_tool_call_body('events_send_chatwoot_message',
                                         base_arguments.except(:deal_id).merge(scheduled_at: scheduled_at)),
             headers: auth_headers
      end.not_to change(Event, :count)
      expect(mcp_result).to include('status' => 'unprocessable_entity',
                                    'error' => 'Provide deal_id or contact_id')
    end

    it 'returns an error when neither send_now nor scheduled_at is provided' do
      expect do
        post '/mcp/messages',
             params: mcp_tool_call_body('events_send_chatwoot_message', base_arguments),
             headers: auth_headers
      end.not_to change(Event, :count)
      expect(mcp_result).to include('status' => 'unprocessable_entity',
                                    'error' => 'Provide send_now=true or scheduled_at')
    end
  end
end
