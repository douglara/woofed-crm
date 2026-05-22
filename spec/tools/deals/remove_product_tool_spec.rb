require 'rails_helper'

RSpec.describe 'MCP tool: deals_remove_product', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:deal) { create(:deal) }
  let!(:product) { create(:product, amount_in_cents: 1_000_000) }
  let!(:deal_product) do
    DealProduct::CreateOrUpdate.new(
      DealProductBuilder.new(ActionController::Parameters.new(deal_id: deal.id, product_id: product.id,
                                                              quantity: 2).permit!).perform,
      {}
    ).call
  end
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized and keeps the deal_product' do
      post '/mcp', params: mcp_tool_call_body('deals_remove_product', { deal_id: deal.id, product_id: product.id }),
                   headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
      expect(DealProduct.exists?(deal_product.id)).to be(true)
    end
  end

  context 'when it is an authenticated user' do
    it 'destroys the deal_product and recalculates the deal totals' do
      expect(deal.reload.total_deal_products_amount_in_cents).to eq(2_000_000)

      expect do
        post '/mcp', params: mcp_tool_call_body('deals_remove_product', { deal_id: deal.id, product_id: product.id }),
                     headers: auth_headers
      end.to change(DealProduct, :count).by(-1)

      expect(mcp_result).to include('deal_id' => deal.id, 'product_id' => product.id)
      expect(deal.reload.total_deal_products_amount_in_cents).to eq(0)
    end

    it 'returns not found when the product is not attached to the deal' do
      other_product = create(:product)
      post '/mcp', params: mcp_tool_call_body('deals_remove_product',
                                               { deal_id: deal.id, product_id: other_product.id }),
                   headers: auth_headers
      expect(mcp_text).to match(/Couldn't find DealProduct/i)
    end

    context 'when required arguments are missing' do
      it 'returns a schema validation error when deal_id or product_id is missing' do
        post '/mcp', params: mcp_tool_call_body('deals_remove_product', { product_id: product.id }),
                     headers: auth_headers
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/deal_id/i)

        post '/mcp', params: mcp_tool_call_body('deals_remove_product', { deal_id: deal.id }), headers: auth_headers
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/product_id/i)
      end
    end
  end
end
