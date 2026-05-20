require 'rails_helper'

RSpec.describe 'MCP tool: deals_update', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:pipeline) { create(:pipeline) }
  let!(:stage) { create(:stage, pipeline: pipeline) }
  let!(:other_stage) { create(:stage, pipeline: pipeline) }
  let!(:contact) { create(:contact) }
  let!(:deal) { create(:deal, contact: contact, stage: stage, pipeline: pipeline, name: 'Old Name') }
  let(:auth_headers) do
    { 'Authorization' => "Bearer #{Users::JsonWebToken.encode_user(user)}",
      'Content-Type' => 'application/json' }
  end
  let(:arguments) do
    { id: deal.id, name: 'Updated Name', stage_id: other_stage.id, status: 'open',
      custom_attributes: { 'source' => 'Inbound' } }
  end

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp/messages', params: mcp_tool_call_body('deals_update', arguments),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
      expect(deal.reload.name).to eq('Old Name')
    end
  end

  context 'when it is an authenticated user' do
    it 'updates all submitted attributes' do
      post '/mcp/messages', params: mcp_tool_call_body('deals_update', arguments), headers: auth_headers
      expect(deal.reload).to have_attributes(
        name: 'Updated Name',
        stage_id: other_stage.id,
        status: 'open',
        custom_attributes: { 'source' => 'Inbound' }
      )
    end

    it 'returns not found when the deal does not exist' do
      post '/mcp/messages', params: mcp_tool_call_body('deals_update', { id: 99_999, name: 'x' }),
                            headers: auth_headers
      expect(mcp_result).to include('status' => 'not_found',
                                    'error' => 'Resource could not be found')
    end
  end
end
