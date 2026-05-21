require 'rails_helper'

RSpec.describe 'MCP tool: deals_create', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:pipeline) { create(:pipeline) }
  let!(:stage) { create(:stage, pipeline: pipeline) }
  let!(:contact) { create(:contact) }
  let(:auth_headers) { mcp_auth_headers(user) }
  let(:arguments) do
    { contact_id: contact.id, stage_id: stage.id, pipeline_id: pipeline.id,
      name: 'Lead site: Rubel', status: 'open', custom_attributes: { 'source' => 'Website' } }
  end
  let(:last_deal) { Deal.last }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      expect do
        post '/mcp', params: mcp_tool_call_body('deals_create', arguments),
                              headers: { 'Content-Type' => 'application/json' }
      end.not_to change(Deal, :count)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'creates a deal with all submitted attributes' do
      expect do
        post '/mcp', params: mcp_tool_call_body('deals_create', arguments), headers: auth_headers
      end.to change(Deal, :count).by(1)
      expect(last_deal).to have_attributes(
        name: 'Lead site: Rubel',
        status: 'open',
        contact_id: contact.id,
        stage_id: stage.id,
        pipeline_id: pipeline.id,
        custom_attributes: { 'source' => 'Website' },
        created_by_id: user.id
      )
    end

    it 'returns a validation error when contact_id does not exist' do
      expect do
        post '/mcp',
             params: mcp_tool_call_body('deals_create', arguments.merge(contact_id: 99_999)),
             headers: auth_headers
      end.not_to change(Deal, :count)
      expect(mcp_text).to include('Validation failed')
      expect(mcp_text).to match(/contact/i)
    end

    context 'when required arguments are missing' do
      it 'returns a schema validation error when contact_id is missing' do
        expect do
          post '/mcp',
               params: mcp_tool_call_body('deals_create', arguments.except(:contact_id)),
               headers: auth_headers
        end.not_to change(Deal, :count)
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/contact_id/i)
      end

      it 'returns a schema validation error when stage_id is missing' do
        expect do
          post '/mcp',
               params: mcp_tool_call_body('deals_create', arguments.except(:stage_id)),
               headers: auth_headers
        end.not_to change(Deal, :count)
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/stage_id/i)
      end
    end
  end
end
