require 'rails_helper'

RSpec.describe 'MCP tool: pipelines_create', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let(:auth_headers) { mcp_auth_headers(user) }
  let(:last_pipeline) { Pipeline.last }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      expect do
        post '/mcp', params: mcp_tool_call_body('pipelines_create', { name: 'sales' }),
                              headers: { 'Content-Type' => 'application/json' }
      end.not_to change(Pipeline, :count)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'creates a pipeline with the given name' do
      expect do
        post '/mcp', params: mcp_tool_call_body('pipelines_create', { name: 'sales' }), headers: auth_headers
      end.to change(Pipeline, :count).by(1)
      expect(last_pipeline).to have_attributes(name: 'sales')
    end

    context 'when required arguments are missing' do
      it 'returns a schema validation error when name is missing' do
        expect do
          post '/mcp', params: mcp_tool_call_body('pipelines_create', {}), headers: auth_headers
        end.not_to change(Pipeline, :count)
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/name/i)
      end
    end
  end
end
