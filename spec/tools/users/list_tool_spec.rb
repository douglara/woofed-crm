require 'rails_helper'

RSpec.describe 'MCP tool: users_list', type: :request do
  let!(:account) { create(:account) }
  let!(:jane) do
    create(:user, full_name: 'Jane Operator', email: 'jane@operator.com',
                  phone: '+5511999990001', job_description: 'sales_representative',
                  language: 'pt-BR', created_at: 1.day.ago)
  end
  let!(:bob) do
    create(:user, full_name: 'Bob Admin', email: 'bob@admin.com',
                  phone: '+5511999990002', job_description: 'ceo', language: 'en')
  end
  let(:auth_headers) { mcp_auth_headers(jane) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_tool_call_body('users_list'),
                   headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns all users when no filter is provided' do
      post '/mcp', params: mcp_tool_call_body('users_list'), headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(mcp_result['data'].pluck('id')).to match_array([jane.id, bob.id])
      expect(mcp_result['pagination']).to include('count', 'page')
    end

    it 'filters by id, partial full_name, email and phone' do
      post '/mcp', params: mcp_tool_call_body('users_list', { id: jane.id }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([jane.id])

      post '/mcp', params: mcp_tool_call_body('users_list', { full_name: 'jane' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([jane.id])

      post '/mcp', params: mcp_tool_call_body('users_list', { email: 'admin.com' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([bob.id])

      post '/mcp', params: mcp_tool_call_body('users_list', { phone: '999990001' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([jane.id])
    end

    it 'filters by exact job_description and language' do
      post '/mcp', params: mcp_tool_call_body('users_list', { job_description: 'ceo' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([bob.id])

      post '/mcp', params: mcp_tool_call_body('users_list', { language: 'pt-BR' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([jane.id])
    end

    it 'filters by created_at and updated_at ranges' do
      post '/mcp', params: mcp_tool_call_body('users_list', { created_from: 2.hours.ago.iso8601 }),
                   headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([bob.id])

      post '/mcp', params: mcp_tool_call_body('users_list', { created_to: 2.hours.ago.iso8601 }),
                   headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([jane.id])

      jane.update!(updated_at: 1.day.ago)
      post '/mcp', params: mcp_tool_call_body('users_list', { updated_from: 2.hours.ago.iso8601 }),
                   headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([bob.id])

      post '/mcp', params: mcp_tool_call_body('users_list', { updated_to: 2.hours.ago.iso8601 }),
                   headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([jane.id])
    end

    it 'paginates results' do
      post '/mcp', params: mcp_tool_call_body('users_list', { per_page: 1, page: 1 }), headers: auth_headers
      expect(mcp_result['data'].size).to eq(1)
      expect(mcp_result['pagination']).to include('count' => 2, 'pages' => 2)
    end

    it 'serializes only safe fields and never the encrypted_password' do
      post '/mcp', params: mcp_tool_call_body('users_list', { id: jane.id }), headers: auth_headers
      record = mcp_result['data'].first
      expect(record.keys).to match_array(
        %w[id full_name email phone job_description language avatar_url created_at updated_at]
      )
    end
  end
end
