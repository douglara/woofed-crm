require 'rails_helper'

RSpec.describe Accounts::UsersController, type: :request do
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
end
