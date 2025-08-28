require 'rails_helper'

RSpec.describe 'Products API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let(:last_product) { Product.last }
  let(:auth_headers) { { 'Authorization': "Bearer #{user.get_jwt_token}", 'Content-Type': 'application/json' } }

  def get_file(name)
    Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/files/#{name}")
  end

  describe 'POST /api/v1/accounts/:account_id/products' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect do
          post "/api/v1/accounts/#{account.id}/products", params: {}
        end.to change(Product, :count).by(0)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        {
          identifier: 'PROD-123',
          amount_in_cents: 150_099,
          quantity_available: 2,
          description: 'Test Product',
          name: 'Sample Product',
          custom_attributes: { 'number_of_doors' => '4' }
        }.to_json
      end

      it 'creates a product' do
        expect do
          post "/api/v1/accounts/#{account.id}/products", params:, headers: auth_headers
        end.to change(Product, :count).by(1)
        expect(response).to have_http_status(:created)
        result = JSON.parse(response.body)
        expect(result['name']).to eq('Sample Product')
        expect(result['identifier']).to eq('PROD-123')
        expect(result['amount_in_cents']).to eq(150_099)
        expect(result['quantity_available']).to eq(2)
        expect(result['description']).to eq('Test Product')
        expect(last_product.custom_attributes['number_of_doors']).to eq('4')
        expect(last_product.account).to eq(account)
      end

      context 'when params are invalid' do
        it 'returns unprocessable_entity for negative amount_in_cents' do
          params = { amount_in_cents: -150_099, name: 'Sample Product' }.to_json

          expect do
            post "/api/v1/accounts/#{account.id}/products", params:, headers: auth_headers
          end.to change(Product, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['errors']).to include('Price Can not be negative')
        end

        it 'returns unprocessable_entity for negative quantity_available' do
          params = { quantity_available: -10, name: 'Sample Product' }.to_json

          expect do
            post "/api/v1/accounts/#{account.id}/products", params:, headers: auth_headers
          end.to change(Product, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['errors']).to include('Quantity available Can not be negative')
        end
      end

      skip 'when attachments are included' do
        let(:params_with_attachments) do
          {
            name: 'Sample Product',
            identifier: 'PROD-123',
            amount_in_cents: 150_099,
            quantity_available: 2,
            description: 'Test Product',
            attachments_attributes: [
              { file: get_file('patrick.png') }, { file: get_file('video_test.mp4') }
            ]
          }.to_json
        end

        it 'creates product with attachments' do
          expect do
            post "/api/v1/accounts/#{account.id}/products", params: params_with_attachments, headers: auth_headers
          end.to change(Product, :count).by(1)
          expect(response).to have_http_status(:created)
          expect(last_product.attachments.count).to eq(2)
          expect(last_product.image_attachments.count).to eq(1)
          expect(last_product.video_attachments.count).to eq(1)
        end
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/products/:id' do
    let!(:product) { create(:product, account:) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/products/#{product.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns product with included deal_products' do
        get "/api/v1/accounts/#{account.id}/products/#{product.id}", headers: auth_headers
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result['name']).to eq(product.name)
        expect(result['identifier']).to eq(product.identifier)
        expect(result['deal_products']).to be_an(Array)
      end

      context 'when product is not found' do
        it 'returns not found' do
          get "/api/v1/accounts/#{account.id}/products/9999", headers: auth_headers
          expect(response).to have_http_status(:not_found)
          result = JSON.parse(response.body)
          expect(result['error']).to eq('Resource could not be found')
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/products/search' do
    let!(:product) { create(:product, account:) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/products/search", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) { { query: { name_eq: product.name } }.to_json }

      it 'returns matching products with pagination' do
        post "/api/v1/accounts/#{account.id}/products/search", params:, headers: auth_headers
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result['data']).to include(a_hash_including('name' => product.name, 'identifier' => product.identifier))
        expect(result['pagination']['count']).to eq(1)
        expect(result['pagination']['page']).to eq(1)
      end

      context 'when no products match the query' do
        let(:params) { { query: { name_eq: 'Nonexistent Product' } }.to_json }

        it 'returns empty results with pagination' do
          post "/api/v1/accounts/#{account.id}/products/search", params:, headers: auth_headers
          expect(response).to have_http_status(:ok)
          result = JSON.parse(response.body)
          expect(result['data']).to be_empty
          expect(result['pagination']['count']).to eq(0)
        end
      end

      it 'return all products when query params is blank' do
        params = { query: {} }.to_json

        post("/api/v1/accounts/#{account.id}/products/search", params:, headers: auth_headers)
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result['data'].size).to eq(Product.count)
      end

      context 'when params is invalid' do
        context 'when there is no ransack prefix to contact params' do
          it 'should raise an error' do
            params = { query: { name: product.name } }.to_json

            post "/api/v1/accounts/#{account.id}/products/search", params:, headers: auth_headers
            expect(response).to have_http_status(:unprocessable_entity)
            json = JSON.parse(response.body)
            expect(json['errors']).to eq('Invalid search parameters')
            expect(json['details']).to eq('No valid predicate for name')
          end
        end
      end
    end
  end
end
