require 'rails_helper'

RSpec.describe 'MCP tool: events_create_note', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:contact) { create(:contact) }
  let!(:deal) { create(:deal, contact: contact) }
  let(:auth_headers) { mcp_auth_headers(user) }
  let(:last_event) { Event.last }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      expect do
        post '/mcp',
             params: mcp_tool_call_body('events_create_note', { deal_id: deal.id, content: 'Hi' }),
             headers: { 'Content-Type' => 'application/json' }
      end.not_to change(Event, :count)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'creates a note attached to a deal' do
      expect do
        post '/mcp',
             params: mcp_tool_call_body('events_create_note',
                                         { deal_id: deal.id, title: 'Follow up', content: 'Called the customer.' }),
             headers: auth_headers
      end.to change(Event, :count).by(1)
      expect(last_event).to have_attributes(kind: 'note', title: 'Follow up',
                                            deal_id: deal.id, contact_id: contact.id, from_me: true)
    end

    it 'creates a note attached to a contact when no deal is given' do
      expect do
        post '/mcp',
             params: mcp_tool_call_body('events_create_note', { contact_id: contact.id, content: 'Reminder' }),
             headers: auth_headers
      end.to change(Event, :count).by(1)
      expect(last_event).to have_attributes(kind: 'note', contact_id: contact.id, deal_id: nil)
    end

    it 'returns an error when neither deal_id nor contact_id is provided' do
      expect do
        post '/mcp',
             params: mcp_tool_call_body('events_create_note', { content: 'Hi' }),
             headers: auth_headers
      end.not_to change(Event, :count)
      expect(mcp_text).to include('Provide deal_id or contact_id')
    end

    context 'when required arguments are missing' do
      it 'returns a schema validation error when content is missing' do
        expect do
          post '/mcp',
               params: mcp_tool_call_body('events_create_note', { deal_id: deal.id }),
               headers: auth_headers
        end.not_to change(Event, :count)
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/content/i)
      end
    end
  end
end
