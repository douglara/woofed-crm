require 'rails_helper'

RSpec.describe Accounts::PipelinesController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let(:pipeline) { create(:pipeline, account: account) }

  describe 'GET /accounts/{account.id}/pipelines' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/pipelines"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'when there are no pipelines' do
        it 'should redirect to welcome page' do
          get "/accounts/#{account.id}/pipelines"
          expect(response).to redirect_to(account_welcome_index_path(account))
        end
      end
      context 'when there are pipelines' do
        it 'should redirect to pipelines index' do
          pipeline
          get "/accounts/#{account.id}/pipelines"
          expect(response).to redirect_to(account_pipeline_path(account, pipeline))
          expect(Pipeline.first.name).to eq(pipeline.name)
        end
      end
    end
  end
end
