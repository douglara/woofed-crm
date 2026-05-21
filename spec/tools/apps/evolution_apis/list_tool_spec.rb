require 'rails_helper'

RSpec.describe 'MCP tool: apps_evolution_apis_list', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:connected_evolution) do
    create(:apps_evolution_api, :connected, name: 'Main WhatsApp', phone: '+5511999990001',
                                            created_at: 1.day.ago)
  end
  let!(:disconnected_evolution) do
    create(:apps_evolution_api, name: 'Backup WhatsApp', phone: '+5511999990002')
  end
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_tool_call_body('apps_evolution_apis_list'),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns all evolution_api integrations when no filter is provided' do
      post '/mcp', params: mcp_tool_call_body('apps_evolution_apis_list'), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to match_array([connected_evolution.id,
                                                             disconnected_evolution.id])
      expect(mcp_result['data'].first).to include('name', 'endpoint_url', 'instance', 'phone',
                                                  'active', 'connection_status')
    end

    it 'filters by id, name, phone and connection_status' do
      post '/mcp', params: mcp_tool_call_body('apps_evolution_apis_list', { id: connected_evolution.id }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([connected_evolution.id])

      post '/mcp', params: mcp_tool_call_body('apps_evolution_apis_list', { name: 'main' }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([connected_evolution.id])

      post '/mcp', params: mcp_tool_call_body('apps_evolution_apis_list', { phone: '+5511999990002' }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([disconnected_evolution.id])

      post '/mcp',
           params: mcp_tool_call_body('apps_evolution_apis_list', { connection_status: 'connected' }),
           headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([connected_evolution.id])
    end

    it 'filters by created_at range' do
      post '/mcp',
           params: mcp_tool_call_body('apps_evolution_apis_list', { created_from: 2.hours.ago.iso8601 }),
           headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([disconnected_evolution.id])

      post '/mcp',
           params: mcp_tool_call_body('apps_evolution_apis_list', { created_to: 2.hours.ago.iso8601 }),
           headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([connected_evolution.id])
    end

    it 'filters by updated_at range' do
      connected_evolution.update!(updated_at: 1.day.ago)
      post '/mcp',
           params: mcp_tool_call_body('apps_evolution_apis_list', { updated_from: 2.hours.ago.iso8601 }),
           headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([disconnected_evolution.id])

      post '/mcp',
           params: mcp_tool_call_body('apps_evolution_apis_list', { updated_to: 2.hours.ago.iso8601 }),
           headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([connected_evolution.id])
    end
  end
end
