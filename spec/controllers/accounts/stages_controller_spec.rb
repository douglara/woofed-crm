require 'rails_helper'

RSpec.describe Accounts::StagesController, type: :request do
  let!(:account) { create(:account) }
  let!(:account_2) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:stage_1) { create(:stage, account:, name: 'stage 1') }
  let!(:stage_2) { create(:stage, account:, name: 'stage 2') }
  let!(:stage_3) { create(:stage, account: account_2, name: 'stage 3') }
  let!(:deal_1_stage_1_open) { create(:deal, account:, stage: stage_1, status: 'open', name: 'deal 1') }
  let!(:deal_2_stage_1_open) { create(:deal, account:, stage: stage_1, status: 'open', name: 'deal 2') }
  let!(:deal_3_stage_1_lost) { create(:deal, account:, stage: stage_1, status: 'lost', name: 'deal 3') }
  let!(:deal_4_stage_2_open) { create(:deal, account:, stage: stage_2, status: 'open', name: 'deal 4') }
  let!(:deal_5_stage_1_won) { create(:deal, account:, stage: stage_1, status: 'won', name: 'deal 5') }

  describe 'GET /accounts/{account.id}/stages/{stage_1.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/stages/#{stage_1.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'should go to stage show page' do
        get "/accounts/#{account.id}/stages/#{stage_1.id}"
        expect(response).to have_http_status(200)
        expect(response.body).to include(stage_1.name)
      end
      context 'when visiting a stage belonging to another account' do
        it 'should go to stage show page' do
          get "/accounts/#{account.id}/stages/#{stage_3.id}"
          expect(response).to have_http_status(200)
          expect(response.body).to include(stage_3.name)
        end
      end

      context 'check filter status deal' do
        context 'when is open' do
          it 'should return only open deals from stage_1' do
            get "/accounts/#{account.id}/stages/#{stage_1.id}?filter_status_deal=open"
            expect(response).to have_http_status(200)
            expect(response.body).to include(stage_1.name)
            expect(response.body).to include(deal_1_stage_1_open.name)
            expect(response.body).to include(deal_2_stage_1_open.name)
            expect(response.body).not_to include(deal_3_stage_1_lost.name)
            expect(response.body).not_to include(deal_4_stage_2_open.name)
            expect(response.body).not_to include(deal_5_stage_1_won.name)
          end
        end
        context 'when is blank' do
          it 'should return only open deals from stage_1' do
            get "/accounts/#{account.id}/stages/#{stage_1.id}"
            expect(response).to have_http_status(200)
            expect(response.body).to include(stage_1.name)
            expect(response.body).to include(deal_1_stage_1_open.name)
            expect(response.body).to include(deal_2_stage_1_open.name)
            expect(response.body).not_to include(deal_3_stage_1_lost.name)
            expect(response.body).not_to include(deal_4_stage_2_open.name)
            expect(response.body).not_to include(deal_5_stage_1_won.name)
          end
        end
        context 'when is lost' do
          it 'should return only lost deals from stage_1' do
            get "/accounts/#{account.id}/stages/#{stage_1.id}?filter_status_deal=lost"
            expect(response).to have_http_status(200)
            expect(response.body).to include(stage_1.name)
            expect(response.body).not_to include(deal_1_stage_1_open.name)
            expect(response.body).not_to include(deal_2_stage_1_open.name)
            expect(response.body).to include(deal_3_stage_1_lost.name)
            expect(response.body).not_to include(deal_4_stage_2_open.name)
            expect(response.body).not_to include(deal_5_stage_1_won.name)
          end
        end
        context 'when is all' do
          it 'should return all deals from stage_1' do
            get "/accounts/#{account.id}/stages/#{stage_1.id}?filter_status_deal=all"
            expect(response).to have_http_status(200)
            expect(response.body).to include(stage_1.name)
            expect(response.body).to include(deal_1_stage_1_open.name)
            expect(response.body).to include(deal_2_stage_1_open.name)
            expect(response.body).to include(deal_3_stage_1_lost.name)
            expect(response.body).not_to include(deal_4_stage_2_open.name)
            expect(response.body).to include(deal_5_stage_1_won.name)
          end
        end
        context 'when is won' do
          it 'should return won deals from stage_1' do
            get "/accounts/#{account.id}/stages/#{stage_1.id}?filter_status_deal=won"
            expect(response).to have_http_status(200)
            expect(response.body).to include(stage_1.name)
            expect(response.body).not_to include(deal_1_stage_1_open.name)
            expect(response.body).not_to include(deal_2_stage_1_open.name)
            expect(response.body).not_to include(deal_3_stage_1_lost.name)
            expect(response.body).not_to include(deal_4_stage_2_open.name)
            expect(response.body).to include(deal_5_stage_1_won.name)
          end
        end
      end
    end
  end
end
