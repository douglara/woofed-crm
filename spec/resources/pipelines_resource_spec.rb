require 'rails_helper'

RSpec.describe 'MCP resource: woofed:///pipelines/{id}', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:pipeline) { create(:pipeline, name: 'sales') }
  let!(:second_stage) { create(:stage, pipeline: pipeline, name: 'Negotiation', position: 2) }
  let!(:first_stage) { create(:stage, pipeline: pipeline, name: 'Qualified', position: 1) }
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_resource_read_body("woofed:///pipelines/#{pipeline.id}"),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns the pipeline with its stages ordered by position' do
      post '/mcp', params: mcp_resource_read_body("woofed:///pipelines/#{pipeline.id}"),
                            headers: auth_headers
      payload = mcp_result

      expect(payload).to include('id' => pipeline.id, 'name' => 'sales')
      expect(payload['stages'].pluck('id')).to eq([first_stage.id, second_stage.id])
      expect(payload['stages'].pluck('name')).to eq(%w[Qualified Negotiation])
    end

    it 'returns an error when the pipeline does not exist' do
      post '/mcp', params: mcp_resource_read_body('woofed:///pipelines/99999'),
                            headers: auth_headers
      expect(mcp_text).to match(/Couldn't find|No resource matches/i)
    end
  end
end
