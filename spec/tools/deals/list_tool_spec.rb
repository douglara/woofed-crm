require 'rails_helper'

RSpec.describe 'MCP tool: deals_list', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:pipeline) { create(:pipeline) }
  let!(:stage) { create(:stage, pipeline: pipeline) }
  let!(:other_stage) { create(:stage, pipeline: pipeline) }
  let!(:contact) { create(:contact) }
  let!(:open_deal) do
    create(:deal, name: 'Rubel Deal', contact: contact, stage: stage, pipeline: pipeline,
                  status: 'open', created_at: 1.day.ago,
                  custom_attributes: { 'source' => 'website' })
  end
  let!(:won_deal) do
    create(:deal, :won, name: 'Other Deal', contact: contact, stage: other_stage, pipeline: pipeline,
                        won_at: 1.hour.ago, lost_reason: '')
  end
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_tool_call_body('deals_list'),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns all deals when no filter is provided' do
      post '/mcp', params: mcp_tool_call_body('deals_list'), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to match_array([open_deal.id, won_deal.id])
    end

    it 'filters by name, status, stage_id, pipeline_id and contact_id' do
      post '/mcp', params: mcp_tool_call_body('deals_list', { name: 'rubel' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([open_deal.id])

      post '/mcp', params: mcp_tool_call_body('deals_list', { status: 'won' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([won_deal.id])

      post '/mcp', params: mcp_tool_call_body('deals_list', { stage_id: stage.id }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([open_deal.id])

      post '/mcp', params: mcp_tool_call_body('deals_list', { pipeline_id: pipeline.id }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to match_array([open_deal.id, won_deal.id])

      post '/mcp', params: mcp_tool_call_body('deals_list', { contact_id: contact.id }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to match_array([open_deal.id, won_deal.id])
    end

    it 'filters by custom_attributes key/value' do
      post '/mcp', params: mcp_tool_call_body('deals_list', { custom_attributes: { source: 'website' } }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([open_deal.id])
    end

    it 'filters by won_at and created_at ranges' do
      post '/mcp', params: mcp_tool_call_body('deals_list', { won_from: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([won_deal.id])

      post '/mcp', params: mcp_tool_call_body('deals_list', { created_from: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([won_deal.id])

      post '/mcp', params: mcp_tool_call_body('deals_list', { created_to: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([open_deal.id])
    end

    it 'filters by updated_at range' do
      open_deal.update!(updated_at: 1.day.ago)
      post '/mcp', params: mcp_tool_call_body('deals_list', { updated_from: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([won_deal.id])

      post '/mcp', params: mcp_tool_call_body('deals_list', { updated_to: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([open_deal.id])
    end
  end
end
