# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deal Products API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:product) { create(:product, account:) }
  let!(:contact) { create(:contact, account:) }
  let!(:deal) { create(:deal, account:, contact:) }
  let!(:deal_product) { create(:deal_product, account:, deal:, product:) }
  let(:last_deal_product) { DealProduct.last }
  let(:last_event) { Event.last }
  let(:auth_headers) { { 'Authorization': "Bearer #{user.get_jwt_token}", 'Content-Type': 'application/json' } }

  describe 'POST /api/v1/accounts/:account_id/deal_products' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/deal_products", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:another_product) do
        create(:product, account:, name: 'Product B', identifier: 'PROD_B', amount_in_cents: 2000)
      end
      let(:params) { { deal_id: deal.id, product_id: another_product.id, quantity: 2 }.to_json }

      it 'creates the deal_product and deal_product_added event' do
        expect do
          post "/api/v1/accounts/#{account.id}/deal_products", params:, headers: auth_headers
        end.to change(DealProduct, :count).by(1)
                                          .and change(Event, :count).by(1)
        expect(response).to have_http_status(:created)
        result = JSON.parse(response.body)
        expect(result['product']['name']).to eq('Product B')
        expect(result['product']['identifier']).to eq('PROD_B')
        expect(result['deal']['id']).to eq(deal.id)
        expect(result['quantity']).to eq(2)
        expect(result['total_amount_in_cents']).to eq(4000) # 2 * 2000
        expect(result['unit_amount_in_cents']).to eq(2000)
        expect(last_event.kind).to eq('deal_product_added')
        expect(last_deal_product.product_identifier).to eq('PROD_B')
        expect(last_deal_product.product_name).to eq('Product B')
        expect(last_deal_product.account).to eq(account)
      end

      context 'when params are invalid' do
        it 'returns unprocessable_entity with errors' do
          params = { deal_id: nil, product_id: nil }.to_json
          expect do
            post "/api/v1/accounts/#{account.id}/deal_products", params:, headers: auth_headers
          end.to change(DealProduct, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['errors']).to include('Deal must exist', 'Product must exist')
        end
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/deal_products/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/deal_products/#{deal_product.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns deal_product with included product and deal' do
        get "/api/v1/accounts/#{account.id}/deal_products/#{deal_product.id}", headers: auth_headers
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result['product']['name']).to eq(product.name)
        expect(result['product']['identifier']).to eq(product.identifier)
        expect(result['deal']['id']).to eq(deal.id)
        expect(result['quantity']).to eq(1)
        expect(result['total_amount_in_cents']).to eq(deal_product.total_amount_in_cents)
        expect(result['unit_amount_in_cents']).to eq(deal_product.unit_amount_in_cents)
      end

      context 'when deal_product is not found ' do
        it 'returns not found' do
          get "/api/v1/accounts/#{account.id}/deal_products/465465465465465465645",
              headers: auth_headers
          expect(response).to have_http_status(:not_found)
          result = JSON.parse(response.body)
          expect(result['error']).to eq('Resource could not be found')
        end
      end
    end
  end
end
