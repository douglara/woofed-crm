require 'rails_helper'

RSpec.describe 'Products API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:product) { create(:product, account:) }
  let(:last_product) { Product.last }

  describe 'POST /api/v1/accounts/{account.id}/products' do
    let(:valid_params) do
      {
        identifier: product.identifier,
        amount_in_cents: product.amount_in_cents,
        quantity_available: 2,
        description: product.description,
        name: product.name,
        custom_attributes: {
          "number_of_doors": '4'
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect do
          post "/api/v1/accounts/#{account.id}/products", params: valid_params
        end.not_to change(Product, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'create product' do
        it do
          expect do
            post "/api/v1/accounts/#{account.id}/products",
                 headers: { 'Authorization': "Bearer #{user.get_jwt_token}" },
                 params: valid_params
          end.to change(Product, :count).by(1)

          expect(response).to have_http_status(:success)
          expect(last_product.custom_attributes['number_of_doors']).to eq('4')
          expect(Product.count).to eq(2)
        end
      end
      context 'when params is invalid' do
        it 'should not create product' do
          expect do
            post "/api/v1/accounts/#{account.id}/products",
                 headers: { 'Authorization': "Bearer #{user.get_jwt_token}" },
                 params: { amount_in_cents: -1 }
          end.to change(Product, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(Product.count).to eq(1)
        end
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/products/{product.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/products/#{product.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'get product' do
        it 'should return product' do
          get "/api/v1/accounts/#{account.id}/products/#{product.id}",
              headers: { 'Authorization': "Bearer #{user.get_jwt_token}" }

          expect(response).to have_http_status(:success)
          expect(response.body).to include(product.name.to_s)
          expect(response.body).to include(product.id.to_s)
        end
        context 'when product is not found' do
          it 'should return not found' do
            get "/api/v1/accounts/#{account.id}/products/69",
                headers: { 'Authorization': "Bearer #{user.get_jwt_token}" }

            expect(response).to have_http_status(:not_found)
          end
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/products/search' do
    let(:valid_params) { { name: product.name, identifier: product.identifier } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/products/search", params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    let(:headers) { { 'Authorization': "Bearer #{user.get_jwt_token}", 'Content-Type': 'application/json' } }

    context 'when it is an authenticated user' do
      context 'search products' do
        it do
          post "/api/v1/accounts/#{account.id}/products/search",
               headers:,
               params: valid_params.to_json

          result = JSON.parse(response.body)
          expect(response).to have_http_status(:success)
          expect(response.body).to include(product.name)
          expect(response.body).to include(product.identifier)
          expect(result['pagination']['count']).to eq(1)
        end
      end

      context 'not found products' do
        let(:params) { { query: { name_eq: 'Product test 123' } }.to_json }
        it do
          post("/api/v1/accounts/#{account.id}/products/search",
               headers:,
               params:)

          result = JSON.parse(response.body)
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include('Product test 123')
          expect(response.body).not_to include(product.name)
          expect(result['pagination']['count']).to eq(0)
        end
      end
    end
  end
end
