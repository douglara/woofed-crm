require 'rails_helper'

RSpec.describe 'MCP tool: events_send_whatsapp_message', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:contact) { create(:contact) }
  let!(:deal) { create(:deal, contact: contact) }
  let!(:evolution_app) { create(:apps_evolution_api) }
  let(:auth_headers) do
    { 'Authorization' => "Bearer #{Users::JsonWebToken.encode_user(user)}",
      'Content-Type' => 'application/json' }
  end
  let(:last_event) { Event.last }
  let(:scheduled_at) { 1.day.from_now.utc.iso8601 }
  let(:base_arguments) do
    { deal_id: deal.id, content: 'How are you?', app_id: evolution_app.id }
  end

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      expect do
        post '/mcp/messages',
             params: mcp_tool_call_body('events_send_whatsapp_message',
                                         base_arguments.merge(scheduled_at: scheduled_at)),
             headers: { 'Content-Type' => 'application/json' }
      end.not_to change(Event, :count)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'schedules a WhatsApp message at scheduled_at' do
      expect do
        post '/mcp/messages',
             params: mcp_tool_call_body('events_send_whatsapp_message',
                                         base_arguments.merge(scheduled_at: scheduled_at)),
             headers: auth_headers
      end.to change(Event, :count).by(1)
      expect(last_event).to have_attributes(
        kind: 'evolution_api_message', title: 'Whatsapp Message',
        app_type: 'Apps::EvolutionApi', app_id: evolution_app.id,
        scheduled_at: Time.parse(scheduled_at), auto_done: true
      )
    end

    it 'returns an error when neither deal_id nor contact_id is provided' do
      expect do
        post '/mcp/messages',
             params: mcp_tool_call_body('events_send_whatsapp_message',
                                         base_arguments.except(:deal_id).merge(scheduled_at: scheduled_at)),
             headers: auth_headers
      end.not_to change(Event, :count)
      expect(mcp_result).to include('status' => 'unprocessable_entity',
                                    'error' => 'Provide deal_id or contact_id')
    end

    it 'returns an error when neither send_now nor scheduled_at is provided' do
      expect do
        post '/mcp/messages',
             params: mcp_tool_call_body('events_send_whatsapp_message', base_arguments),
             headers: auth_headers
      end.not_to change(Event, :count)
      expect(mcp_result).to include('status' => 'unprocessable_entity',
                                    'error' => 'Provide send_now=true or scheduled_at')
    end
  end
end
