require 'rails_helper'

RSpec.describe 'MCP tool: pipelines_update', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:pipeline) { create(:pipeline, name: 'old name') }
  let(:auth_headers) do
    { 'Authorization' => "Bearer #{Users::JsonWebToken.encode_user(user)}",
      'Content-Type' => 'application/json' }
  end

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp/messages',
           params: mcp_tool_call_body('pipelines_update', { id: pipeline.id, name: 'new name' }),
           headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
      expect(pipeline.reload.name).to eq('old name')
    end
  end

  context 'when it is an authenticated user' do
    it 'updates the pipeline name' do
      post '/mcp/messages',
           params: mcp_tool_call_body('pipelines_update', { id: pipeline.id, name: 'new name' }),
           headers: auth_headers
      expect(pipeline.reload.name).to eq('new name')
    end

    it 'returns not found when the pipeline does not exist' do
      post '/mcp/messages',
           params: mcp_tool_call_body('pipelines_update', { id: 99_999, name: 'x' }),
           headers: auth_headers
      expect(mcp_result).to include('status' => 'not_found',
                                    'error' => 'Resource could not be found')
    end

    context 'when required arguments are missing' do
      it 'returns a schema validation error when id is missing' do
        post '/mcp/messages',
             params: mcp_tool_call_body('pipelines_update', { name: 'x' }),
             headers: auth_headers
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/id/i)
      end
    end
  end
end
