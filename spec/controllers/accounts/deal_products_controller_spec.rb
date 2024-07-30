require 'rails_helper'

RSpec.describe Accounts::DealProductsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let(:product) { create(:product, account: account) }
  let!(:pipeline) { create(:pipeline, account: account) }
  let!(:stage) { create(:stage, account: account, pipeline: pipeline) }
  let!(:deal) { create(:deal, account: account, stage: stage, contact: contact) }
  let(:deal_product) { create(:deal_product, account: account, deal: deal, product: product) }

  describe 'DELETE /accounts/{account.id}/deal_products/{deal_product.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/accounts/#{account.id}/deal_products/#{deal_product.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'delete deal_product' do
        it do
          delete "/accounts/#{account.id}/deal_products/#{deal_product.id}"
          expect(response).to have_http_status(:redirect)
          expect(DealProduct.count).to eq(0)
        end
      end
    end
  end
  describe 'GET /accounts/{account.id}/deal_products/new?deal_id={deal.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deal_products/new?deal_id=#{deal.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'should access deal_product new page' do
        it do
          get "/accounts/#{account.id}/deal_products/new?deal_id=#{deal.id}"
          expect(response).to have_http_status(200)
          expect(response.body).to include('select_product_search')
        end
      end
    end
  end
  describe 'POST /accounts/{account.id}/deal_products' do
    let(:valid_params) { { deal_product: { deal_id: deal.id, product_id: product.id } } }
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/deal_products", params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'create deal_product' do
        it do
          post "/accounts/#{account.id}/deal_products", params: valid_params
          expect(response).to have_http_status(302)
          expect(DealProduct.count).to eq(1)
        end
        context 'when params is not valid' do
          context 'when params not contain deal_id' do
            it 'should raise an error' do
              invalid_params = { deal_product: { product_id: product.id } }
              post "/accounts/#{account.id}/deal_products", params: invalid_params
              expect(response).to have_http_status(:unprocessable_entity)
              expect(response.body).to include('Deal must exist')
              expect(DealProduct.count).to eq(0)
            end
          end
          context 'when params not contain product_id' do
            it 'should raise an error' do
              invalid_params = { deal_product: { deal_id: deal.id } }
              post "/accounts/#{account.id}/deal_products", params: invalid_params
              expect(response).to have_http_status(:unprocessable_entity)
              expect(response.body).to include('Product must exist')
              expect(DealProduct.count).to eq(0)
            end
          end
        end
      end
    end
  end
  describe 'GET /accounts/{account.id}/deal_products/select_product_search?query=query' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deal_products/select_product_search?query=query"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'select product search component' do
        it do
          get "/accounts/#{account.id}/deal_products/select_product_search"
          expect(response).to have_http_status(200)
        end
        context 'when there is query parameter' do
          it 'should return product' do
            get "/accounts/#{account.id}/deal_products/select_product_search?query=#{product.name}"
            expect(response).to have_http_status(200)
            expect(response.body).to include(product.name)
          end
          context 'when query paramenter is not founded' do
            it 'should return 0 products' do
              get "/accounts/#{account.id}/deal_products/select_product_search?query=teste"
              expect(response).to have_http_status(200)
              expect(response.body).not_to include('teste')
              expect(response.body).not_to include(product.name)
            end
          end
        end
      end
    end
  end
end
