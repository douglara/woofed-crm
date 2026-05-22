require 'rails_helper'

RSpec.describe 'MCP tool: deals_add_product', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:deal) { create(:deal) }
  let!(:product) do
    create(:product, name: 'Car', identifier: 'SKU-CAR-001', amount_in_cents: 1_000_035)
  end
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized and does not create the deal_product' do
      post '/mcp', params: mcp_tool_call_body('deals_add_product', { deal_id: deal.id, product_id: product.id }),
                   headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
      expect(DealProduct.exists?(deal: deal, product: product)).to be(false)
    end
  end

  context 'when it is an authenticated user' do
    it 'attaches the product and snapshots name/identifier/unit_amount_in_cents from the catalog, and recalculates totals' do
      expect do
        post '/mcp', params: mcp_tool_call_body('deals_add_product',
                                                 { deal_id: deal.id, product_id: product.id, quantity: 3 }),
                     headers: auth_headers
      end.to change(DealProduct, :count).by(1)

      payload = mcp_result
      expect(payload).to include(
        'deal_id' => deal.id,
        'product_id' => product.id,
        'product_name' => 'Car',
        'product_identifier' => 'SKU-CAR-001',
        'unit_amount_in_cents' => 1_000_035,
        'quantity' => 3,
        'total_amount_in_cents' => 3_000_105
      )
      expect(deal.reload.total_deal_products_amount_in_cents).to eq(3_000_105)
    end

    it 'returns a validation error when the product is already attached to the deal' do
      create(:deal_product, deal: deal, product: product)

      expect do
        post '/mcp', params: mcp_tool_call_body('deals_add_product', { deal_id: deal.id, product_id: product.id }),
                     headers: auth_headers
      end.not_to change(DealProduct, :count)

      expect(mcp_text).to match(/Validation failed/i)
    end

    context 'when required arguments are missing' do
      it 'returns a schema validation error when deal_id or product_id is missing' do
        post '/mcp', params: mcp_tool_call_body('deals_add_product', { product_id: product.id }), headers: auth_headers
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/deal_id/i)

        post '/mcp', params: mcp_tool_call_body('deals_add_product', { deal_id: deal.id }), headers: auth_headers
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/product_id/i)
      end
    end
  end
end
