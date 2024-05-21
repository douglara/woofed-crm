require 'rails_helper'

RSpec.describe Accounts::DealsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:pipeline) { create(:pipeline, account: account) }
  let!(:stage) { create(:stage, account: account, pipeline: pipeline) }
  let!(:stage_2) { create(:stage, account: account, pipeline: pipeline, name: 'Stage 2') }
  let!(:contact) { create(:contact, account: account) }
  let(:event) { create(:event, account: account, deal: deal, kind: 'activity') }

  describe 'POST /accounts/{account.id}/deals' do
    let(:valid_params) { { deal: { name: 'Deal 1', contact_id: contact.id, stage_id: stage.id } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/accounts/#{account.id}/deals", params: valid_params }.not_to change(Deal, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'create deal' do
        it do
          expect do
            post "/accounts/#{account.id}/deals",
                 params: valid_params
          end.to change(Deal, :count).by(1)
          expect(response).to redirect_to(account_deal_path(account, Deal.last))
        end

        it 'create deal without stage' do
          expect do
            post "/accounts/#{account.id}/deals",
                 params: valid_params.except('stage_id').merge({ pipeline_id: pipeline.id })
          end.to change(Deal, :count).by(1)

          expect(response).to redirect_to(account_deal_path(account, Deal.last))
          expect(Deal.last.stage).to eq(stage)
        end
      end
    end
  end

  describe 'PUT /accounts/{account.id}/deals/:id' do
    let(:deal) { create(:deal, account: account, stage: stage) }
    let(:valid_params) { { deal: { name: 'Deal Updated' } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/accounts/#{account.id}/deals/#{deal.id}", params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'should update deal' do
        it do
          put "/accounts/#{account.id}/deals/#{deal.id}",
              params: valid_params

          # expect(response).to have_http_status(:success)
          expect(deal.reload.name).to eq('Deal Updated')
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/:id' do
    let(:deal) { create(:deal, account: account, stage: stage) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/#{deal.id}"

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'shows the deal' do
        get "/accounts/#{account.id}/deals/#{deal.id}"

        expect(response).to have_http_status(:success)
        expect(response.body).to include(deal.name)
      end
    end
  end
  describe 'DELETE /accounts/{account.id}/deals/:id' do
    let!(:deal) { create(:deal, account: account, stage: stage) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/#{deal.id}"

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'delete deal' do
        it do
          expect do
            delete "/accounts/#{account.id}/deals/#{deal.id}"
            expect(response).to redirect_to(root_path)
          end.to change(Deal, :count).by(-1)
        end
        it 'with events' do
          event
          expect do
            delete "/accounts/#{account.id}/deals/#{deal.id}"
            expect(response).to redirect_to(root_path)
          end.to change(Deal, :count).by(-1) and change(Contact, :count).by(-1)
          expect(account.events.count).to eq(0)
        end
      end
    end
  end

  describe 'test events to do and done pages' do
    let!(:deal) { create(:deal, account: account, stage: stage, contact: contact) }
    let!(:event_to_do) do
      create(:event, account: account, deal: deal, kind: 'activity', title: 'event to do', contact: contact)
    end
    let!(:event_done) do
      create(:event, account: account, deal: deal, kind: 'activity', title: 'event done',
                     done_at: Time.current - 3.minutes, contact: contact)
    end

    describe 'GET /accounts/{account.id}/deals/:id/events_to_do' do
      context 'when it is an unauthenticated user' do
        it 'returns unauthorized' do
          get "/accounts/#{account.id}/deals/#{deal.id}/events_to_do"
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'when it is an authenticated user' do
        before do
          sign_in(user)
        end

        it 'should return only to_do events' do
          get "/accounts/#{account.id}/deals/#{deal.id}/events_to_do"
          expect(response.body).to include('event to do')
          expect(response.body).not_to include('event done')
          expect(response.body).not_to include('id="pagination"')
        end
        context 'check if pagination is enabled' do
          it 'should return turboframe with id pagination' do
            5.times do
              create(:event, account: account, deal: deal, kind: 'activity', title: 'event to do', contact: contact)
            end
            get "/accounts/#{account.id}/deals/#{deal.id}/events_to_do"
            expect(response.body).to include('id="pagination_events_to_do"')
          end
        end
      end
    end
    describe 'GET /accounts/{account.id}/deals/:id/events_done' do
      context 'when it is an unauthenticated user' do
        it 'returns unauthorized' do
          get "/accounts/#{account.id}/deals/#{deal.id}/events_done"
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'when it is an authenticated user' do
        before do
          sign_in(user)
        end

        it 'should return only done events' do
          get "/accounts/#{account.id}/deals/#{deal.id}/events_done"
          expect(response.body).to include('event done')
          expect(response.body).not_to include('event to do')
          expect(response.body).not_to include('id="pagination"')
        end
        context 'check if pagination is enabled' do
          it 'should return turboframe with id pagination' do
            5.times do
              create(:event, account: account, deal: deal, kind: 'activity', title: 'event done',
                             done_at: Time.current - 3.minutes, contact: contact)
            end
            get "/accounts/#{account.id}/deals/#{deal.id}/events_done"
            expect(response.body).to include('id="pagination_events_done"')
          end
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/:id/deal_products' do
    let!(:deal) { create(:deal, account: account, stage: stage, contact: contact) }
    let(:product) { create(:product, account: account) }
    let!(:deal_product) { create(:deal_product, account: account, deal: deal, product: product) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/#{deal.id}/deal_products"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'should return only deal_products' do
        get "/accounts/#{account.id}/deals/#{deal.id}/deal_products"
        expect(response.body).to include(product.name)
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/:id/edit_product?deal_product_id={deal_product.id}' do
    let!(:deal) { create(:deal, account: account, stage: stage, contact: contact) }
    let(:product) { create(:product, account: account) }
    let!(:deal_product) { create(:deal_product, account: account, deal: deal, product: product) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/#{deal.id}/edit_product?deal_product_id=#{deal_product.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      it 'edit product on deal page' do
        get "/accounts/#{account.id}/deals/#{deal.id}/edit_product?deal_product_id=#{deal_product.id}"
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/deals/:id/update_product?deal_product_id={deal_product.id}' do
    let!(:deal) { create(:deal, account: account, stage: stage, contact: contact) }
    let(:product) { create(:product, account: account) }
    let!(:deal_product) { create(:deal_product, account: account, deal: deal, product: product) }
    let(:valid_params) do
      { product: { name: 'Product Updated Name', amount_in_cents: '63.580,36' } }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/deals/#{deal.id}/update_product?deal_product_id=#{deal_product.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'update product' do
        it do
          patch "/accounts/#{account.id}/deals/#{deal.id}/update_product?deal_product_id=#{deal_product.id}",
                params: valid_params
          expect(response).to have_http_status(302)
          expect(product.reload.name).to eq('Product Updated Name')
          expect(product.amount_in_cents).to eq(6_358_036)
        end
        context 'when quantity_available is invalid' do
          it 'when quantity_available is negative' do
            invalid_params = { product: { quantity_available: '-30' } }
            patch "/accounts/#{account.id}/deals/#{deal.id}/update_product?deal_product_id=#{deal_product.id}",
                  params: invalid_params
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Can not be negative')
          end
        end

        context 'when amount_in_cents is invalid' do
          it 'when amount_in_cents is negative' do
            invalid_params = { product: { amount_in_cents: '-150000' } }
            patch "/accounts/#{account.id}/deals/#{deal.id}/update_product?deal_product_id=#{deal_product.id}",
                  params: invalid_params
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Can not be negative')
          end
        end
      end
    end
  end
end
