require 'rails_helper'

RSpec.describe 'MCP tool: stages_update', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:pipeline) { create(:pipeline) }
  let!(:stage) { create(:stage, pipeline: pipeline, name: 'Old Name', position: 1) }
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp',
           params: mcp_tool_call_body('stages_update', { id: stage.id, name: 'New Name' }),
           headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
      expect(stage.reload.name).to eq('Old Name')
    end
  end

  context 'when it is an authenticated user' do
    it 'updates the stage name and position' do
      post '/mcp',
           params: mcp_tool_call_body('stages_update', { id: stage.id, name: 'New Name', position: 2 }),
           headers: auth_headers
      expect(stage.reload).to have_attributes(name: 'New Name', position: 2)
    end

    it 'returns not found when the stage does not exist' do
      post '/mcp',
           params: mcp_tool_call_body('stages_update', { id: 99_999, name: 'x' }),
           headers: auth_headers
      expect(mcp_text).to match(/not.*found|Couldn't find/i)
    end

    context 'when required arguments are missing' do
      it 'returns a schema validation error when id is missing' do
        post '/mcp',
             params: mcp_tool_call_body('stages_update', { name: 'x' }),
             headers: auth_headers
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/id/i)
      end
    end
  end
end
