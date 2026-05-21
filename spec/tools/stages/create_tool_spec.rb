require 'rails_helper'

RSpec.describe 'MCP tool: stages_create', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:pipeline) { create(:pipeline) }
  let!(:existing_stage) { create(:stage, pipeline: pipeline, name: 'Existing', position: 1) }
  let(:auth_headers) { mcp_auth_headers(user) }
  let(:last_stage) { Stage.last }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      expect do
        post '/mcp',
             params: mcp_tool_call_body('stages_create', { pipeline_id: pipeline.id, name: 'Qualified' }),
             headers: { 'Content-Type' => 'application/json' }
      end.not_to change(Stage, :count)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'creates a stage inside the given pipeline and appends to the end by default' do
      expect do
        post '/mcp',
             params: mcp_tool_call_body('stages_create', { pipeline_id: pipeline.id, name: 'Qualified' }),
             headers: auth_headers
      end.to change(Stage, :count).by(1)
      expect(last_stage).to have_attributes(name: 'Qualified', pipeline_id: pipeline.id, position: 2)
    end

    it 'creates a stage at the given position' do
      post '/mcp',
           params: mcp_tool_call_body('stages_create',
                                       { pipeline_id: pipeline.id, name: 'First', position: 1 }),
           headers: auth_headers
      expect(last_stage).to have_attributes(name: 'First', position: 1)
      expect(existing_stage.reload.position).to eq(2)
    end

    it 'returns not found when the pipeline does not exist' do
      expect do
        post '/mcp',
             params: mcp_tool_call_body('stages_create', { pipeline_id: 99_999, name: 'x' }),
             headers: auth_headers
      end.not_to change(Stage, :count)
      expect(mcp_text).to match(/not.*found|Couldn't find/i)
    end

    context 'when required arguments are missing' do
      it 'returns a schema validation error when pipeline_id is missing' do
        expect do
          post '/mcp',
               params: mcp_tool_call_body('stages_create', { name: 'x' }),
               headers: auth_headers
        end.not_to change(Stage, :count)
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/pipeline_id/i)
      end

      it 'returns a schema validation error when name is missing' do
        expect do
          post '/mcp',
               params: mcp_tool_call_body('stages_create', { pipeline_id: pipeline.id }),
               headers: auth_headers
        end.not_to change(Stage, :count)
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/name/i)
      end
    end
  end
end
