require 'rails_helper'

RSpec.describe 'MCP tool: deals_remove_assignee', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:deal) { create(:deal) }
  let!(:assignee) { create(:deal_assignee, deal: deal, user: other_user) }
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized and keeps the assignee' do
      post '/mcp', params: mcp_tool_call_body('deals_remove_assignee', { deal_id: deal.id, user_id: other_user.id }),
                   headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
      expect(DealAssignee.exists?(assignee.id)).to be(true)
    end
  end

  context 'when it is an authenticated user' do
    it 'removes the assignee from the deal and returns the destroyed record' do
      expect do
        post '/mcp', params: mcp_tool_call_body('deals_remove_assignee', { deal_id: deal.id, user_id: other_user.id }),
                     headers: auth_headers
      end.to change(DealAssignee, :count).by(-1)

      expect(mcp_result).to include('deal_id' => deal.id, 'user_id' => other_user.id)
      expect(deal.reload.users).not_to include(other_user)
    end

    it 'returns not found when the user is not an assignee of the deal' do
      assignee.destroy!
      post '/mcp', params: mcp_tool_call_body('deals_remove_assignee', { deal_id: deal.id, user_id: other_user.id }),
                   headers: auth_headers
      expect(mcp_text).to match(/Couldn't find DealAssignee/i)
    end

    context 'when required arguments are missing' do
      it 'returns a schema validation error when deal_id or user_id is missing' do
        post '/mcp', params: mcp_tool_call_body('deals_remove_assignee', { user_id: other_user.id }), headers: auth_headers
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/deal_id/i)

        post '/mcp', params: mcp_tool_call_body('deals_remove_assignee', { deal_id: deal.id }), headers: auth_headers
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/user_id/i)
      end
    end
  end
end
