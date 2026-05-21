require 'rails_helper'

RSpec.describe 'MCP resource: woofed:///deals/{id}', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:pipeline) { create(:pipeline) }
  let!(:stage) { create(:stage, pipeline: pipeline) }
  let!(:contact) { create(:contact) }
  let!(:deal) do
    create(:deal, contact: contact, stage: stage, pipeline: pipeline,
                  name: 'Deal name', status: 'open', position: 1)
  end
  let!(:deal_assignee) { create(:deal_assignee, deal: deal, user: user) }
  let!(:product) { create(:product) }
  let!(:deal_product) { create(:deal_product, deal: deal, product: product) }
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_resource_read_body("woofed:///deals/#{deal.id}"),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns the deal with all fields and its contact, stage, pipeline, assignees and products' do
      post '/mcp', params: mcp_resource_read_body("woofed:///deals/#{deal.id}"),
                            headers: auth_headers
      payload = mcp_result

      expect(payload).to include(
        'id' => deal.id,
        'name' => 'Deal name',
        'status' => 'open',
        'position' => 1,
        'stage_id' => stage.id,
        'pipeline_id' => pipeline.id,
        'contact_id' => contact.id
      )
      expect(payload['contact']).to include('id' => contact.id, 'full_name' => contact.full_name,
                                            'email' => contact.email, 'phone' => contact.phone)
      expect(payload['stage']).to include('id' => stage.id, 'name' => stage.name,
                                          'pipeline_id' => pipeline.id)
      expect(payload['pipeline']).to include('id' => pipeline.id, 'name' => pipeline.name)
      expect(payload['deal_assignees'].pluck('id')).to include(deal_assignee.id)
      expect(payload['deal_assignees'].pluck('user_id')).to include(user.id)
      expect(payload['deal_products'].pluck('id')).to include(deal_product.id)
      expect(payload['deal_products'].pluck('product_id')).to include(product.id)
    end

    it 'returns an error when the deal does not exist' do
      post '/mcp', params: mcp_resource_read_body('woofed:///deals/99999'),
                            headers: auth_headers
      expect(mcp_text).to match(/Couldn't find|No resource matches/i)
    end
  end
end
