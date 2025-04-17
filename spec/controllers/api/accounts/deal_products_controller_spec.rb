# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deal Products API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:product) { create(:product, account:) }
  let!(:contact) { create(:contact, account:) }
  let!(:pipeline) { create(:pipeline, account:) }
  let!(:stage) { create(:stage, account:, pipeline:) }
  let!(:deal) { create(:deal, account:, contact:, stage:) }
  let!(:deal_product) { create(:deal_product, account:, deal:, product:) }
  let(:last_deal_product) { DealProduct.last }

  describe 'POST /api/v1/accounts/{account.id}/deal_products' do
    let(:another_product) { create(:product, account:) }

    let(:valid_params) do
      {
        product_id: another_product.id,
        deal_id: deal.id
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect do
          post "/api/v1/accounts/#{account.id}/deal_products", params: valid_params
        end.not_to change(DealProduct, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'create deal_product' do
        expect do
          post "/api/v1/accounts/#{account.id}/deal_products",
               headers: { 'Authorization': "Bearer #{user.get_jwt_token}" },
               params: valid_params
        end.to change(DealProduct, :count).by(1)

        expect(response).to have_http_status(:success)
        expect(last_deal_product.product.id).to eq(another_product.id)
        expect(last_deal_product.deal.id).to eq(deal.id)
        expect(DealProduct.count).to eq(2)
      end

      it 'when params is invalid should raise error' do
        expect do
          post "/api/v1/accounts/#{account.id}/deal_products",
               headers: { 'Authorization': "Bearer #{user.get_jwt_token}" },
               params: { product_id: 'teste', deal_id: '123' }
        end.to change(DealProduct, :count).by(0)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(DealProduct.count).to eq(1)
      end
      context 'when attempting to create a duplicate deal_product for the same deal and product' do
        it 'should raise an error' do
          params = { deal_id: deal.id, product_id: product.id  }
          expect do
            post "/api/v1/accounts/#{account.id}/deal_products",
            headers: { 'Authorization': "Bearer #{user.get_jwt_token}" },
            params: params
          end.to change(DealProduct, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('has already been added to this deal')
        end
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/deal_products/{product.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/deal_products/#{deal_product.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'get deal_product' do
        it 'should return deal_product' do
          get "/api/v1/accounts/#{account.id}/deal_products/#{deal_product.id}",
              headers: { 'Authorization': "Bearer #{user.get_jwt_token}" }

          expect(response).to have_http_status(:success)
          expect(response.body).to include(deal_product.product.name.to_s)
          expect(response.body).to include(deal_product.deal.name.to_s)
        end
        it 'when deal_product is not found' do
          get "/api/v1/accounts/#{account.id}/deal_products/1",
              headers: { 'Authorization': "Bearer #{user.get_jwt_token}" }

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
