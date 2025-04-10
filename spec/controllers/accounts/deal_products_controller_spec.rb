require 'rails_helper'

RSpec.describe Accounts::DealProductsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:contact) { create(:contact, account:) }
  let(:product) { create(:product, account:) }
  let!(:pipeline) { create(:pipeline, account:) }
  let!(:stage) { create(:stage, account:, pipeline:) }
  let!(:deal) { create(:deal, account:, stage:, contact:) }
  let!(:deal_product) { create(:deal_product, account:, deal:, product:) }
  let(:last_event) { Event.last }

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
      context 'should delete deal_product and create deal_product_removed event' do
        it do
          expect do
            delete "/accounts/#{account.id}/deal_products/#{deal_product.id}"
          end.to change(DealProduct, :count).by(-1)
                                            .and change(Event, :count).by(1)
          expect(response).to have_http_status(:redirect)
          expect(last_event.kind).to eq('deal_product_removed')
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
      context 'should create deal_product and deal_product_added event' do
        it do
          expect do
            post "/accounts/#{account.id}/deal_products", params: valid_params
          end.to change(DealProduct, :count).by(1)
                                            .and change(Event, :count).by(1)
          expect(response).to have_http_status(302)
          expect(last_event.kind).to eq('deal_product_added')
        end
        context 'when params is not valid' do
          context 'when params not contain deal_id' do
            it 'should raise an error' do
              invalid_params = { deal_product: { product_id: product.id } }
              expect do
                post "/accounts/#{account.id}/deal_products", params: invalid_params
              end.to change(DealProduct, :count).by(0)
              expect(response).to have_http_status(:unprocessable_entity)
              expect(response.body).to include('Deal must exist')
            end
          end
          context 'when params not contain product_id' do
            it 'should raise an error' do
              invalid_params = { deal_product: { deal_id: deal.id } }
              expect do
                post "/accounts/#{account.id}/deal_products", params: invalid_params
              end.to change(DealProduct, :count).by(0)
              expect(response).to have_http_status(:unprocessable_entity)
              expect(response.body).to include('Product must exist')
            end
          end
        end
      end
    end
  end
end
