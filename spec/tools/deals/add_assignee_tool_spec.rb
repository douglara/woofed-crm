require 'rails_helper'

RSpec.describe 'MCP tool: deals_add_assignee', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:deal) { create(:deal) }
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized and does not create the assignee' do
      post '/mcp', params: mcp_tool_call_body('deals_add_assignee', { deal_id: deal.id, user_id: other_user.id }),
                   headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
      expect(DealAssignee.exists?(deal: deal, user: other_user)).to be(false)
    end
  end

  context 'when it is an authenticated user' do
    it 'assigns the user to the deal and returns the assignee record' do
      expect do
        post '/mcp', params: mcp_tool_call_body('deals_add_assignee', { deal_id: deal.id, user_id: other_user.id }),
                     headers: auth_headers
      end.to change(DealAssignee, :count).by(1)

      expect(mcp_result).to include('deal_id' => deal.id, 'user_id' => other_user.id)
      expect(deal.reload.users).to include(other_user)
    end

    it 'returns a validation error when the user is already an assignee' do
      create(:deal_assignee, deal: deal, user: other_user)

      expect do
        post '/mcp', params: mcp_tool_call_body('deals_add_assignee', { deal_id: deal.id, user_id: other_user.id }),
                     headers: auth_headers
      end.not_to change(DealAssignee, :count)

      expect(mcp_text).to match(/Validation failed/i)
      expect(mcp_text).to match(/user/i)
    end

    it 'returns not found when the deal does not exist' do
      post '/mcp', params: mcp_tool_call_body('deals_add_assignee', { deal_id: 99_999, user_id: other_user.id }),
                   headers: auth_headers
      expect(mcp_text).to match(/Couldn't find Deal/i)
    end

    it 'returns not found when the user does not exist' do
      post '/mcp', params: mcp_tool_call_body('deals_add_assignee', { deal_id: deal.id, user_id: 99_999 }),
                   headers: auth_headers
      expect(mcp_text).to match(/Couldn't find User/i)
    end

    context 'when required arguments are missing' do
      it 'returns a schema validation error when deal_id or user_id is missing' do
        post '/mcp', params: mcp_tool_call_body('deals_add_assignee', { user_id: other_user.id }), headers: auth_headers
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/deal_id/i)

        post '/mcp', params: mcp_tool_call_body('deals_add_assignee', { deal_id: deal.id }), headers: auth_headers
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/user_id/i)
      end
    end
  end
end
