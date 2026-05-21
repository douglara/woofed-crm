require 'rails_helper'

RSpec.describe 'MCP resource: woofed:///products/{id}', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:product) do
    create(:product, name: 'Car', identifier: 'SKU-123', amount_in_cents: 1_000_035,
                     quantity_available: 2, description: 'Nice car',
                     custom_attributes: { 'number_of_doors' => '4' })
  end
  let!(:deal) { create(:deal) }
  let!(:deal_product) { create(:deal_product, deal: deal, product: product) }
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_resource_read_body("woofed:///products/#{product.id}"),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns the product with all fields and its deal_products' do
      post '/mcp', params: mcp_resource_read_body("woofed:///products/#{product.id}"),
                            headers: auth_headers
      payload = mcp_result

      expect(payload).to include(
        'id' => product.id,
        'name' => 'Car',
        'identifier' => 'SKU-123',
        'amount_in_cents' => 1_000_035,
        'quantity_available' => 2,
        'description' => 'Nice car',
        'custom_attributes' => { 'number_of_doors' => '4' }
      )
      expect(payload['deal_products'].pluck('id')).to include(deal_product.id)
      expect(payload['deal_products'].pluck('deal_id')).to include(deal.id)
    end

    it 'returns an error when the product does not exist' do
      post '/mcp', params: mcp_resource_read_body('woofed:///products/99999'),
                            headers: auth_headers
      expect(mcp_text).to match(/Couldn't find|No resource matches/i)
    end
  end
end
