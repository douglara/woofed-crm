require 'rails_helper'

RSpec.describe 'MCP tool: pipelines_list', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:sales) { create(:pipeline, name: 'sales') }
  let!(:onboarding) { create(:pipeline, name: 'onboarding') }
  let!(:sales_stage_one) { create(:stage, pipeline: sales, name: 'Qualified', position: 1) }
  let!(:sales_stage_two) { create(:stage, pipeline: sales, name: 'Negotiation', position: 2) }
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_tool_call_body('pipelines_list'),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns pipelines with their stages ordered by position' do
      post '/mcp', params: mcp_tool_call_body('pipelines_list'), headers: auth_headers
      expect(mcp_result['data'].pluck('name')).to eq(%w[onboarding sales])
      sales_payload = mcp_result['data'].find { |p| p['name'] == 'sales' }
      expect(sales_payload['stages'].pluck('name')).to eq(%w[Qualified Negotiation])
      expect(mcp_result['pagination']).to include('count', 'page')
    end

    it 'filters pipelines by name and id' do
      post '/mcp', params: mcp_tool_call_body('pipelines_list', { name: 'sales' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([sales.id])

      post '/mcp', params: mcp_tool_call_body('pipelines_list', { id: onboarding.id }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([onboarding.id])
    end

    it 'paginates results' do
      post '/mcp', params: mcp_tool_call_body('pipelines_list', { per_page: 1, page: 1 }), headers: auth_headers
      expect(mcp_result['data'].size).to eq(1)
      expect(mcp_result['pagination']).to include('count' => 2, 'pages' => 2)
    end
  end
end
