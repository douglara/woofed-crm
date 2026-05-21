require 'rails_helper'

RSpec.describe 'MCP tool: products_list', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:cheap_product) do
    create(:product, name: 'Cheap item', identifier: 'CHEAP', amount_in_cents: 1_000,
                     quantity_available: 5, custom_attributes: { 'category' => 'A' },
                     created_at: 1.day.ago)
  end
  let!(:expensive_product) do
    create(:product, name: 'Expensive item', identifier: 'EXP', amount_in_cents: 100_000,
                     quantity_available: 1, custom_attributes: { 'category' => 'B' })
  end
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_tool_call_body('products_list'),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns all products when no filter is provided' do
      post '/mcp', params: mcp_tool_call_body('products_list'), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to match_array([cheap_product.id, expensive_product.id])
    end

    it 'filters by name, identifier, amount range and custom_attributes' do
      post '/mcp', params: mcp_tool_call_body('products_list', { name: 'cheap' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([cheap_product.id])

      post '/mcp', params: mcp_tool_call_body('products_list', { identifier: 'EXP' }), headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([expensive_product.id])

      post '/mcp',
           params: mcp_tool_call_body('products_list', { amount_in_cents_min: 10_000 }),
           headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([expensive_product.id])

      post '/mcp',
           params: mcp_tool_call_body('products_list', { custom_attributes: { category: 'A' } }),
           headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([cheap_product.id])
    end

    it 'filters by created_at range' do
      post '/mcp', params: mcp_tool_call_body('products_list', { created_from: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([expensive_product.id])

      post '/mcp', params: mcp_tool_call_body('products_list', { created_to: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([cheap_product.id])
    end

    it 'filters by updated_at range' do
      cheap_product.update!(updated_at: 1.day.ago)
      post '/mcp', params: mcp_tool_call_body('products_list', { updated_from: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([expensive_product.id])

      post '/mcp', params: mcp_tool_call_body('products_list', { updated_to: 2.hours.ago.iso8601 }),
                            headers: auth_headers
      expect(mcp_result['data'].pluck('id')).to eq([cheap_product.id])
    end
  end
end
