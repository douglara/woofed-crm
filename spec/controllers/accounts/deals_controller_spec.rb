require 'rails_helper'

RSpec.describe Accounts::DealsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:pipeline) { create(:pipeline, account: account) }
  let!(:stage) { create(:stage, account: account, pipeline: pipeline) }
  let!(:stage_2) { create(:stage, account: account, pipeline: pipeline, name: 'Stage 2') }
  let!(:contact) { create(:contact, account: account) }

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
            params: valid_params.except('stage_id').merge({pipeline_id: pipeline.id})
          end.to change(Deal, :count).by(1)
  
          expect(response).to redirect_to(account_deal_path(account, Deal.last))
          expect(Deal.last.stage).to eq(stage)
        end
      end
    end
  end
end