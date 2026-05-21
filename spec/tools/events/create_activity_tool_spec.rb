require 'rails_helper'

RSpec.describe 'MCP tool: events_create_activity', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:contact) { create(:contact) }
  let!(:deal) { create(:deal, contact: contact) }
  let(:auth_headers) { mcp_auth_headers(user) }
  let(:last_event) { Event.last }
  let(:scheduled_at) { 1.day.from_now.utc.iso8601 }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      expect do
        post '/mcp',
             params: mcp_tool_call_body('events_create_activity',
                                         { deal_id: deal.id, title: 'Call', scheduled_at: scheduled_at }),
             headers: { 'Content-Type' => 'application/json' }
      end.not_to change(Event, :count)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'schedules an activity on a deal timeline' do
      expect do
        post '/mcp',
             params: mcp_tool_call_body('events_create_activity',
                                         { deal_id: deal.id, title: 'Follow-up call',
                                           content: 'Confirm proposal', scheduled_at: scheduled_at }),
             headers: auth_headers
      end.to change(Event, :count).by(1)
      expect(last_event).to have_attributes(kind: 'activity', title: 'Follow-up call',
                                            deal_id: deal.id, contact_id: contact.id,
                                            scheduled_at: Time.parse(scheduled_at), done: false)
    end

    it 'schedules an activity on a contact timeline when no deal is given' do
      post '/mcp',
           params: mcp_tool_call_body('events_create_activity',
                                       { contact_id: contact.id, title: 'Welcome', scheduled_at: scheduled_at }),
           headers: auth_headers
      expect(last_event).to have_attributes(kind: 'activity', contact_id: contact.id, deal_id: nil)
    end

    it 'returns an error when neither deal_id nor contact_id is provided' do
      expect do
        post '/mcp',
             params: mcp_tool_call_body('events_create_activity', { title: 'No target' }),
             headers: auth_headers
      end.not_to change(Event, :count)
      expect(mcp_text).to include('Provide deal_id or contact_id')
    end

    context 'when required arguments are missing' do
      it 'returns a schema validation error when title is missing' do
        expect do
          post '/mcp',
               params: mcp_tool_call_body('events_create_activity', { deal_id: deal.id }),
               headers: auth_headers
        end.not_to change(Event, :count)
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/title/i)
      end
    end
  end
end
