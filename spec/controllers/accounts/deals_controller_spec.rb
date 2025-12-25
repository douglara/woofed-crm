require 'rails_helper'

RSpec.describe Accounts::DealsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:pipeline) { create(:pipeline) }
  let!(:stage) { create(:stage, pipeline:) }
  let!(:stage_2) { create(:stage, pipeline:, name: 'Stage 2') }
  let!(:contact) { create(:contact) }
  let(:event) { create(:event, deal:, kind: 'activity') }
  let(:last_event) { Event.last }
  let(:last_deal) { Deal.last }
  let(:last_deal_assignee) { DealAssignee.last }

  describe 'POST /accounts/{account.id}/deals' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/accounts/#{account.id}/deals", params: {} }.not_to change(Deal, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) { { deal: { name: 'Deal 1', contact_id: contact.id, stage_id: stage.id } } }

      before do
        sign_in(user)
      end

      context 'create deal, deal_opened event and deal_assignee' do
        it do
          expect do
            post "/accounts/#{account.id}/deals",
                 params:
          end.to change(Deal, :count).by(1)
                                     .and change(Event, :count).by(1)
                                     .and change(DealAssignee, :count).by(1)
          expect(response).to redirect_to(account_deal_path(account, last_deal))
          expect(last_event.kind).to eq('deal_opened')
          expect(last_deal.creator).to eq(user)
          expect(last_deal_assignee.user).to eq(user)
          expect(last_deal_assignee.deal).to eq(last_deal)
        end
      end
    end
  end

  describe 'PUT /accounts/{account.id}/deals/:id' do
    let!(:deal) { create(:deal, stage:) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/accounts/#{account.id}/deals/#{deal.id}", params: {}
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) { { deal: { name: 'Deal Updated' } } }

      before do
        sign_in(user)
      end

      context 'should update deal ' do
        it do
          put("/accounts/#{account.id}/deals/#{deal.id}",
              params:)

          expect(deal.reload.name).to eq('Deal Updated')
          expect(response).to have_http_status(:redirect)
        end
      end
      context 'update deal position and create deal_stage_change event' do
        around(:each) do |example|
          Sidekiq::Testing.inline! do
            example.run
          end
        end
        let!(:deal_stage_1_position_1) { create(:deal, stage:, position: 1) }
        let!(:deal_stage_1_position_2) { create(:deal, stage:, position: 2) }
        let!(:deal_stage_1_position_3) { create(:deal, stage:, position: 3) }
        let!(:deal_stage_2_position_1) { create(:deal, stage: stage_2, position: 1) }
        let!(:deal_stage_2_position_2) { create(:deal, stage: stage_2, position: 2) }
        let!(:deal_stage_2_position_3) { create(:deal, stage: stage_2, position: 3) }
        skip 'between different stages' do
          it 'stage 1 position 3 to stage 2 position 1' do
            params =  { deal: { stage_id: stage_2.id, position: 1 } }

            put("/accounts/#{account.id}/deals/#{deal_stage_1_position_3.id}",
                params:)
            # expect(response).to have_http_status(:success)
            expect(deal_stage_1_position_3.reload.position).to eq(1)
            expect(deal_stage_1_position_3.reload.stage).to eq(stage_2)
            expect(deal_stage_2_position_1.reload.position).to eq(2)
          end
          it 'stage 1 position 1 to stage 2 position 1' do
            params =  { deal: { stage_id: stage_2.id, position: 1 } }
            expect do
              put("/accounts/#{account.id}/deals/#{deal_stage_1_position_1.id}",
                  params:)
            end.to change(Event, :count).by(1)
            # expect(response).to have_http_status(:success)
            expect(deal_stage_1_position_1.reload.position).to eq(1)
            expect(deal_stage_1_position_1.reload.stage).to eq(stage_2)
            expect(deal_stage_2_position_1.reload.position).to eq(2)
            expect(last_event.kind).to eq('deal_stage_change')
          end
        end
        context 'in the same stage' do
          it 'position 3 to position 1' do
            params = { deal: { stage_id: stage.id, position: 1 } }
            put("/accounts/#{account.id}/deals/#{deal_stage_1_position_3.id}",
                params:)
            # expect(response).to have_http_status(:success)
            expect(deal_stage_1_position_3.reload.position).to eq(1)
            expect(deal_stage_1_position_3.reload.stage).to eq(stage)
          end
          it 'position 1 to position 3' do
            params = { deal: { stage_id: stage.id, position: 3 } }
            put("/accounts/#{account.id}/deals/#{deal_stage_1_position_1.id}",
                params:)
            # expect(response).to have_http_status(:success)
            expect(deal_stage_1_position_1.reload.position).to eq(3)
            expect(deal_stage_1_position_1.reload.stage).to eq(stage)
          end
          it 'position 2 to position 1' do
            params = { deal: { stage_id: stage.id, position: 1 } }
            put("/accounts/#{account.id}/deals/#{deal_stage_1_position_2.id}",
                params:)
            # expect(response).to have_http_status(:success)
            expect(deal_stage_1_position_2.reload.position).to eq(1)
            expect(deal_stage_1_position_2.reload.stage).to eq(stage)
          end
        end
      end

      context 'update status deal' do
        it 'update to won and create deal_won event' do
          params = { deal: { status: 'won' } }
          expect do
            put("/accounts/#{account.id}/deals/#{deal.id}",
                params:)
          end.to change(Event, :count).by(1)
          expect(last_event.kind).to eq('deal_won')
        end
        it 'update to lost and create deal_lost event' do
          params = { deal: { status: 'lost' } }
          expect do
            put("/accounts/#{account.id}/deals/#{deal.id}",
                params:)
          end.to change(Event, :count).by(1)
          expect(last_event.kind).to eq('deal_lost')
        end
        context 'when deal is won ' do
          let!(:won_deal) { create(:deal, stage:, status: 'won') }
          it 'update to open and create reopen_lost event' do
            params = { deal: { status: 'open' } }
            expect do
              put("/accounts/#{account.id}/deals/#{won_deal.id}",
                  params:)
            end.to change(Event, :count).by(1)
            expect(last_event.kind).to eq('deal_reopened')
          end
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/:id' do
    let(:deal) do
      create(:deal, :lost, stage:, creator: user)
    end

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
        expect(response.body).to include(deal.creator.full_name)
        expect(response.body).not_to include(I18n.t('activerecord.attributes.deal.won_at'))
        expect(response.body).not_to include(I18n.t('activerecord.attributes.deal.lost_at'))
      end

      context 'when deal is lost' do
        let(:lost_at) { Time.zone.parse('2025-01-15 10:30:00') }
        let(:lost_reason) { 'test lost reason' }

        let(:deal) do
          create(:deal, :lost, stage:, creator: user, lost_reason: lost_reason,
                              lost_at: lost_at)
        end

        it 'show lost at date and lost reason' do
          get "/accounts/#{account.id}/deals/#{deal.id}"
          expect(response).to have_http_status(:success)
          expect(response.body).to include(lost_at.to_s)
          expect(response.body).to include(lost_reason)
          expect(response.body).to include(I18n.t('activerecord.attributes.deal.lost_at'))
          expect(response.body).not_to include(I18n.t('activerecord.attributes.deal.won_at'))
        end
      end

      context 'when deal is won' do
        let(:won_at) { Time.zone.parse('2025-02-20 15:45:00') }

        let(:deal) do
          create(:deal, :won, stage:, creator: user,
                              won_at: won_at)
        end

        it 'show won at date' do
          get "/accounts/#{account.id}/deals/#{deal.id}"

          expect(response).to have_http_status(:success)
          expect(response.body).to include(won_at.to_s)
          expect(response.body).to include(I18n.t('activerecord.attributes.deal.won_at'))
          expect(response.body).not_to include(I18n.t('activerecord.attributes.deal.lost_at'))
        end
      end
    end
  end

  describe 'DELETE /accounts/{account.id}/deals/:id' do
    let!(:deal) { create(:deal, stage:) }

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

      context 'delete a deal and its associated events' do
        it do
          expect do
            delete "/accounts/#{account.id}/deals/#{deal.id}"
            expect(response).to redirect_to(root_path)
          end.to change(Deal, :count).by(-1).and change(Event, :count).by(-1)
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/:id/edit' do
    let!(:deal) { create(:deal, :lost, stage:, contact:, creator: user, lost_reason: 'test lost reason',
                           lost_at: Time.zone.parse('2024-01-15 10:30:00')) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/#{deal.id}/edit"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'shows the edit deal page' do
        get "/accounts/#{account.id}/deals/#{deal.id}/edit"
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('Created by')
        expect(response.body).not_to include('Lost at')
        expect(flash[:error]).to be_nil
      end

      context 'when deal is won' do
        let(:deal) do
          create(:deal, :lost, stage:, creator: user,
                              won_at: Time.zone.parse('2025-01-15 10:30:00'))
        end

        it 'show won at field date' do
          won_deal = create(:deal, :won, stage:, creator: user,
                                       won_at: Time.zone.parse('2025-02-20 15:45:00'))
          get "/accounts/#{account.id}/deals/#{won_deal.id}"

          expect(response).to have_http_status(:success)
          expect(response.body).to include('Won at')
        end
      end
    end
  end

  describe 'test events to do and done pages' do
    let!(:deal) { create(:deal, stage:, contact:) }
    let!(:event_to_do) do
      create(:event, deal:, kind: 'activity', title: 'event to do', contact:)
    end
    let!(:event_done) do
      create(:event, deal:, kind: 'activity', title: 'event done',
                     done_at: Time.current - 3.minutes, contact:)
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
              create(:event, deal:, kind: 'activity', title: 'event to do', contact:)
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
              create(:event, deal:, kind: 'activity', title: 'event done',
                             done_at: Time.current - 3.minutes, contact:)
            end
            get "/accounts/#{account.id}/deals/#{deal.id}/events_done"
            expect(response.body).to include('id="pagination_events_done"')
          end
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/:id/deal_products' do
    let!(:deal) { create(:deal, stage:, contact:) }
    let(:product) { create(:product) }
    let!(:deal_product) do
      create(:deal_product, deal:, product:, product_name: 'Product teste deal name',
                            unit_amount_in_cents: '10000', quantity: '65984123', product_identifier: 'Identifier 123 test')
    end

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
        expect(response.body).to include('10000')
        expect(response.body).to include('65984123')
        expect(response.body).to include('Identifier 123 test')
        expect(response.body).to include('Product teste deal name')
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/:id/deal_assignees' do
    let!(:deal) { create(:deal, stage:, contact:) }
    let!(:deal_assignee) { create(:deal_assignee, deal:, user:) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/#{deal.id}/deal_assignees"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'should return only deal_assignees' do
        get "/accounts/#{account.id}/deals/#{deal.id}/deal_assignees"
        expect(response.body).to include(user.full_name)
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/:id/edit_deal_product?deal_product_id={deal_product.id}' do
    let!(:deal) { create(:deal, stage:, contact:) }
    let(:product) { create(:product) }
    let!(:deal_product) do
      create(:deal_product, deal:, product:, product_name: 'Product teste deal name',
                            unit_amount_in_cents: '10000', quantity: '65984123', product_identifier: 'Identifier 123 test')
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/#{deal.id}/edit_deal_product?deal_product_id=#{deal_product.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      it 'edit deal product on deal page' do
        get "/accounts/#{account.id}/deals/#{deal.id}/edit_deal_product?deal_product_id=#{deal_product.id}"
        expect(response).to have_http_status(200)
        expect(response.body).to include('10000')
        expect(response.body).to include('65984123')
        expect(response.body).to include('Identifier 123 test')
        expect(response.body).to include('Product teste deal name')
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/deals/:id/update_deal_product?deal_product_id={deal_product.id}' do
    let!(:deal_product) { create(:deal_product) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/deals/#{deal_product.deal.id}/update_deal_product?deal_product_id=#{deal_product.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'update deal product' do
        let(:params) do
          { deal_product: { product_name: 'Product Updated Name', unit_amount_in_cents: '63.580,36', quantity: 5,
                            product_identifier: '123456' } }
        end
        it do
          patch("/accounts/#{account.id}/deals/#{deal_product.deal.id}/update_deal_product?deal_product_id=#{deal_product.id}",
                params:)
          expect(response).to have_http_status(302)
          total_deal_products_amount_in_cents = deal_product.deal.deal_products.sum(:total_amount_in_cents)
          expect(deal_product.reload.product_name).to eq('Product Updated Name')
          expect(deal_product.unit_amount_in_cents).to eq(6_358_036)
          expect(deal_product.quantity).to eq(5)
          expect(deal_product.product_identifier).to eq('123456')
          expect(deal_product.deal.total_deal_products_amount_in_cents).to eq(total_deal_products_amount_in_cents)
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals' do
    let!(:deal) { create(:deal, stage:, contact:, creator: user, name: 'Test Deal') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'returns deals page' do
        get "/accounts/#{account.id}/deals"
        expect(response.body).to include('Deals')
        expect(response.body).to include('tooltip-deal-kanban-link')
        doc = Nokogiri::HTML(response.body)
        table_body = doc.at_css('tbody#deals').text
        expect(table_body).to include(deal.name)
      end

      context 'when there is query params' do
        context 'when query params match with deals name' do
          it 'should show deals on deals table' do
            get "/accounts/#{account.id}/deals", params: { query: deal.name }
            expect(response.body).to include('Deals')
            expect(response.body).to include('tooltip-deal-kanban-link')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#deals').text
            expect(table_body).to include(deal.name)
          end
        end

        context 'when query params does not match with deals' do
          it 'should return an empty deals table' do
            get "/accounts/#{account.id}/deals", params: { query: 'aasdsdfgdfghdfghcxvxcvbcvbn' }
            expect(response.body).to include('Deals')
            expect(response.body).to include('tooltip-deal-kanban-link')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#deals').text
            expect(table_body).not_to include(deal.name)
          end
        end

        context 'when query params match with contact full_name' do
          it 'should show deals associated with the contact' do
            get "/accounts/#{account.id}/deals", params: { query: contact.full_name }
            expect(response.body).to include('Deals')
            expect(response.body).to include('tooltip-deal-kanban-link')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#deals').text
            expect(table_body).to include(deal.name)
          end
        end

        context 'when query params match partially with deal name' do
          it 'should show deals with partial match' do
            get "/accounts/#{account.id}/deals", params: { query: 'Test' }
            expect(response.body).to include('Deals')
            expect(response.body).to include('tooltip-deal-kanban-link')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#deals').text
            expect(table_body).to include(deal.name)
          end
        end

        context 'when query params are case-insensitive' do
          it 'should show deals regardless of case' do
            get "/accounts/#{account.id}/deals", params: { query: 'test DEAL' }
            expect(response.body).to include('Deals')
            expect(response.body).to include('tooltip-deal-kanban-link')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#deals').text
            expect(table_body).to include(deal.name)
          end
        end

        context 'when there are multiple deals and query does not match any' do
          let!(:deal2) { create(:deal, stage:, contact:, creator: user, name: 'Another Deal') }
          let!(:deal3) { create(:deal, stage:, contact:, creator: user, name: 'Third Deal') }

          it 'should return an empty deals table' do
            get "/accounts/#{account.id}/deals", params: { query: 'Nonexistent Deal' }
            expect(response.body).to include('Deals')
            expect(response.body).to include('tooltip-deal-kanban-link')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#deals').text
            expect(table_body).not_to include(deal.name)
            expect(table_body).not_to include(deal2.name)
            expect(table_body).not_to include(deal3.name)
          end
        end

        context 'when query params is deal id' do
          it 'should show deal on deals table' do
            get "/accounts/#{account.id}/deals", params: { query: deal.id.to_s }
            expect(response.body).to include('Deals')
            expect(response.body).to include('tooltip-deal-kanban-link')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#deals').text
            expect(table_body).to include(deal.name)
          end
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/new' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/new"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'when there is contact_id on deals params' do
        it 'returns new deals page' do
          get "/accounts/#{account.id}/deals/new", params: { deal: { contact_id: contact.id } }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('New deal')
        end
      end

      context 'when there is no contact_id on deals params' do
        it 'renders new_select_contact with status unprocessable_entity' do
          get "/accounts/#{account.id}/deals/new"
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('select_contact_search')
          expect(response.body).to match(/Contact can&#39;t be blank/)
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/new_select_contact' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/new_select_contact"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'returns new select contact deals page' do
        get "/accounts/#{account.id}/deals/new_select_contact"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('select_contact_search')
        expect(response.body).to include('Continue')
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/:id/mark_as_lost' do
    let!(:deal) { create(:deal, stage:) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/#{deal.id}/mark_as_lost"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let!(:deal_lost_reason) { create(:deal_lost_reason) }
      let!(:stage) { create(:stage) }

      before do
        sign_in(user)
      end

      it 'returns deal_lost_reasons and stages and mark as lost deals page' do
        get "/accounts/#{account.id}/deals/#{deal.id}/mark_as_lost"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Mark as Lost')
        expect(response.body).to include(deal_lost_reason.name)
        expect(response.body).to include(stage.name)
      end

      context 'when there is no deal lost reasons' do
        before do
          DealLostReason.destroy_all
        end

        it 'does not display deal lost reasons select' do
          get "/accounts/#{account.id}/deals/#{deal.id}/mark_as_lost"
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include(I18n.t('activerecord.models.deal.select_a_reason'))
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/:id/mark_as_won' do
    let!(:deal) { create(:deal, stage:) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/#{deal.id}/mark_as_won"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let!(:stage) { create(:stage) }

      before do
        sign_in(user)
      end

      it 'returns stages and mark as won deals page' do
        get "/accounts/#{account.id}/deals/#{deal.id}/mark_as_won"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t('activerecord.models.deal.mark_as_won'))
        expect(response.body).to include(stage.name)
      end
    end
  end
end
