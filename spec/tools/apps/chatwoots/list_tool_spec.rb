require 'rails_helper'

RSpec.describe 'MCP tool: apps_chatwoots_list', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:active_chatwoot) do
    create(:apps_chatwoots, :skip_validate, name: 'Sales Inbox', status: 'active',
                                            chatwoot_endpoint_url: 'https://chat.example.com',
                                            chatwoot_account_id: 42, inboxes: [{ 'id' => 1 }],
                                            created_at: 1.day.ago)
  end
  let!(:inactive_chatwoot) do
    create(:apps_chatwoots, :skip_validate, :inactive, name: 'Old Inbox',
                                                       chatwoot_endpoint_url: 'https://old.example.com',
                                                       chatwoot_account_id: 99)
  end
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_tool_call_body('apps_chatwoots_list'),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns all chatwoot integrations when no filter is provided' do
      post '/mcp', params: mcp_tool_call_body('apps_chatwoots_list'), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to match_array([active_chatwoot.id, inactive_chatwoot.id])
      expect(mcp_result['data'].first).to include('name', 'status', 'chatwoot_endpoint_url',
                                                  'chatwoot_account_id', 'inboxes')
    end

    it 'filters by id, name, status, chatwoot_endpoint_url and chatwoot_account_id' do
      post '/mcp', params: mcp_tool_call_body('apps_chatwoots_list', { id: active_chatwoot.id }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([active_chatwoot.id])

      post '/mcp', params: mcp_tool_call_body('apps_chatwoots_list', { name: 'sales' }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([active_chatwoot.id])

      post '/mcp', params: mcp_tool_call_body('apps_chatwoots_list', { status: 'inactive' }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([inactive_chatwoot.id])

      post '/mcp',
           params: mcp_tool_call_body('apps_chatwoots_list', { chatwoot_endpoint_url: 'old.example' }),
           headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([inactive_chatwoot.id])

      post '/mcp',
           params: mcp_tool_call_body('apps_chatwoots_list', { chatwoot_account_id: 42 }),
           headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([active_chatwoot.id])
    end

    it 'filters by created_at range' do
      post '/mcp', params: mcp_tool_call_body('apps_chatwoots_list', { created_from: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([inactive_chatwoot.id])

      post '/mcp', params: mcp_tool_call_body('apps_chatwoots_list', { created_to: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([active_chatwoot.id])
    end

    it 'filters by updated_at range' do
      active_chatwoot.update!(updated_at: 1.day.ago)
      post '/mcp', params: mcp_tool_call_body('apps_chatwoots_list', { updated_from: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([inactive_chatwoot.id])

      post '/mcp', params: mcp_tool_call_body('apps_chatwoots_list', { updated_to: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([active_chatwoot.id])
    end
  end
end
