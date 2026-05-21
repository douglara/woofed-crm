require 'rails_helper'

RSpec.describe 'MCP tool: deals_mark_won', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:deal) { create(:deal) }
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_tool_call_body('deals_mark_won', { id: deal.id }),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
      expect(deal.reload.status).to eq('open')
    end
  end

  context 'when it is an authenticated user' do
    it 'marks the deal as won and sets won_at to now by default' do
      freeze_time do
        post '/mcp', params: mcp_tool_call_body('deals_mark_won', { id: deal.id }), headers: auth_headers
        expect(deal.reload).to have_attributes(status: 'won', won_at: Time.current, lost_at: nil)
      end
    end

    it 'returns not found when the deal does not exist' do
      post '/mcp', params: mcp_tool_call_body('deals_mark_won', { id: 99_999 }), headers: auth_headers
      expect(mcp_text).to match(/not.*found|Couldn't find/i)
    end

    context 'when required arguments are missing' do
      it 'returns a schema validation error when id is missing' do
        post '/mcp', params: mcp_tool_call_body('deals_mark_won', {}), headers: auth_headers
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/id/i)
      end
    end
  end
end
