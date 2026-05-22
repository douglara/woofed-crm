require 'rails_helper'

RSpec.describe 'MCP tool: deals_update_product', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:deal) { create(:deal) }
  let!(:product) { create(:product, name: 'Car', identifier: 'SKU-CAR-001', amount_in_cents: 1_000_000) }
  let!(:deal_product) do
    DealProduct::CreateOrUpdate.new(
      DealProductBuilder.new(ActionController::Parameters.new(deal_id: deal.id, product_id: product.id,
                                                              quantity: 1).permit!).perform,
      {}
    ).call
  end
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized and does not modify the deal_product' do
      post '/mcp', params: mcp_tool_call_body('deals_update_product',
                                               { deal_id: deal.id, product_id: product.id, quantity: 5 }),
                   headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
      expect(deal_product.reload.quantity).to eq(1)
    end
  end

  context 'when it is an authenticated user' do
    it 'updates quantity and recalculates total_amount_in_cents and the deal totals' do
      post '/mcp', params: mcp_tool_call_body('deals_update_product',
                                               { deal_id: deal.id, product_id: product.id, quantity: 4 }),
                   headers: auth_headers
      expect(mcp_result).to include('quantity' => 4, 'total_amount_in_cents' => 4_000_000)
      expect(deal_product.reload).to have_attributes(quantity: 4, total_amount_in_cents: 4_000_000)
      expect(deal.reload.total_deal_products_amount_in_cents).to eq(4_000_000)
    end

    it 'updates unit_amount_in_cents and recalculates totals' do
      post '/mcp', params: mcp_tool_call_body('deals_update_product',
                                               { deal_id: deal.id, product_id: product.id,
                                                 unit_amount_in_cents: 500_000 }),
                   headers: auth_headers
      expect(mcp_result).to include('unit_amount_in_cents' => 500_000, 'total_amount_in_cents' => 500_000)
      expect(deal_product.reload).to have_attributes(unit_amount_in_cents: 500_000, total_amount_in_cents: 500_000)
    end

    it 'requires at least one of quantity or unit_amount_in_cents' do
      post '/mcp', params: mcp_tool_call_body('deals_update_product',
                                               { deal_id: deal.id, product_id: product.id }),
                   headers: auth_headers
      expect(mcp_text).to match(/Provide quantity or unit_amount_in_cents/i)
    end

    it 'returns not found when the product is not attached to the deal' do
      other_product = create(:product)
      post '/mcp', params: mcp_tool_call_body('deals_update_product',
                                               { deal_id: deal.id, product_id: other_product.id, quantity: 2 }),
                   headers: auth_headers
      expect(mcp_text).to match(/Couldn't find DealProduct/i)
    end

    context 'when required arguments are missing' do
      it 'returns a schema validation error when deal_id or product_id is missing' do
        post '/mcp', params: mcp_tool_call_body('deals_update_product', { product_id: product.id, quantity: 2 }),
                     headers: auth_headers
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/deal_id/i)

        post '/mcp', params: mcp_tool_call_body('deals_update_product', { deal_id: deal.id, quantity: 2 }),
                     headers: auth_headers
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/product_id/i)
      end
    end
  end
end
