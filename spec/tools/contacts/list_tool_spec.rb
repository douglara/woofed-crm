require 'rails_helper'

RSpec.describe 'MCP tool: contacts_list', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let(:auth_headers) { mcp_auth_headers(user) }
  let!(:john) do
    create(:contact, full_name: 'John Doe', email: 'john@example.com',
                     phone: '+5511999990001', created_at: 1.day.ago)
  end
  let!(:jane) { create(:contact, full_name: 'Jane Roe', email: 'jane@other.com', phone: '+5511999990002') }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_tool_call_body('contacts_list'),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns all contacts when no filter is provided' do
      post '/mcp', params: mcp_tool_call_body('contacts_list'), headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(mcp_result['data'].pluck('id')).to match_array([john.id, jane.id])
      expect(mcp_result['pagination']).to include('count', 'page')
    end

    it 'filters by partial full_name, email, phone and id' do
      post '/mcp', params: mcp_tool_call_body('contacts_list', { full_name: 'john' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([john.id])

      post '/mcp', params: mcp_tool_call_body('contacts_list', { email: 'other' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([jane.id])

      post '/mcp', params: mcp_tool_call_body('contacts_list', { phone: '999990001' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([john.id])

      post '/mcp', params: mcp_tool_call_body('contacts_list', { id: jane.id }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([jane.id])
    end

    it 'filters by created_at range' do
      post '/mcp', params: mcp_tool_call_body('contacts_list', { created_from: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([jane.id])

      post '/mcp', params: mcp_tool_call_body('contacts_list', { created_to: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([john.id])
    end

    it 'filters by updated_at range' do
      john.update!(updated_at: 1.day.ago)
      post '/mcp', params: mcp_tool_call_body('contacts_list', { updated_from: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([jane.id])

      post '/mcp', params: mcp_tool_call_body('contacts_list', { updated_to: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([john.id])
    end

    it 'filters by custom_attributes key/value' do
      john.update!(custom_attributes: { 'city' => 'RJ' })
      post '/mcp', params: mcp_tool_call_body('contacts_list', { custom_attributes: { city: 'RJ' } }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([john.id])
    end

    it 'paginates results' do
      post '/mcp', params: mcp_tool_call_body('contacts_list', { per_page: 1, page: 1 }), headers: auth_headers
      expect(mcp_result['data'].size).to eq(1)
      expect(mcp_result['pagination']).to include('count' => 2, 'pages' => 2)
    end
  end
end
