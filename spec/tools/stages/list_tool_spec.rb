require 'rails_helper'

RSpec.describe 'MCP tool: stages_list', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:sales) { create(:pipeline, name: 'sales') }
  let!(:onboarding) { create(:pipeline, name: 'onboarding') }
  let!(:sales_qualified) { create(:stage, pipeline: sales, name: 'Qualified', position: 1) }
  let!(:sales_negotiation) { create(:stage, pipeline: sales, name: 'Negotiation', position: 2) }
  let!(:onboarding_kickoff) { create(:stage, pipeline: onboarding, name: 'Kickoff', position: 1) }
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_tool_call_body('stages_list'),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns all stages ordered by pipeline and position' do
      post '/mcp', params: mcp_tool_call_body('stages_list'), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to match_array(
        [sales_qualified.id, sales_negotiation.id, onboarding_kickoff.id]
      )
    end

    it 'filters by pipeline_id, id and name' do
      post '/mcp',
           params: mcp_tool_call_body('stages_list', { pipeline_id: sales.id }),
           headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([sales_qualified.id, sales_negotiation.id])

      post '/mcp',
           params: mcp_tool_call_body('stages_list', { id: onboarding_kickoff.id }),
           headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([onboarding_kickoff.id])

      post '/mcp',
           params: mcp_tool_call_body('stages_list', { name: 'negotiation' }),
           headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([sales_negotiation.id])
    end
  end
end
