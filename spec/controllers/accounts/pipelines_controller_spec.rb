require 'rails_helper'

RSpec.describe Accounts::PipelinesController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }

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
          it 'redirects to welcome page' do
            get "/accounts/#{account.id}/pipelines"
            expect(response).to redirect_to(account_welcome_index_path(account))
          end
        end

        context 'when there are pipelines' do
          let!(:pipeline) { create(:pipeline) }

          it 'redirects to pipeline show page' do
            get "/accounts/#{account.id}/pipelines"
            expect(response).to redirect_to(account_pipeline_path(account, pipeline))
            expect(Pipeline.first.name).to eq(pipeline.name)
          end
        end
    end
  end

  describe 'GET /accounts/{account.id}/pipelines/new' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/pipelines/new"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      it 'renders new pipeline page' do
        get "/accounts/#{account.id}/pipelines/new"
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'POST /accounts/{account.id}/pipelines' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/accounts/#{account.id}/pipelines", params: {} }.not_to change(Pipeline, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) { { pipeline: { name: 'New Pipeline', account_id: account.id } } }

      before do
        sign_in(user)
      end

      it 'creates a pipeline' do
        expect do
          post "/accounts/#{account.id}/pipelines", params: params
        end.to change(Pipeline, :count).by(1)
        expect(response).to redirect_to(account_pipeline_path(account, Pipeline.last))
        expect(Pipeline.last.name).to eq('New Pipeline')
      end

      skip 'when pipeline creation fails' do
        it 'renders new with unprocessable_entity status' do
          params = { pipeline: { name: '', account_id: account.id } }
          expect do
            post "/accounts/#{account.id}/pipelines", params: params
          end.not_to change(Pipeline, :count)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/pipelines/{pipeline.id}/edit' do
    let!(:pipeline) { create(:pipeline) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/pipelines/#{pipeline.id}/edit"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders edit pipeline page' do
        get "/accounts/#{account.id}/pipelines/#{pipeline.id}/edit"
        expect(response).to have_http_status(200)
        expect(response.body).to include(pipeline.name)
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/pipelines/{pipeline.id}' do
    let!(:pipeline) { create(:pipeline) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/pipelines/#{pipeline.id}", params: {}
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) { { pipeline: { name: 'Updated Pipeline' } } }

      before do
        sign_in(user)
      end

      it 'updates the pipeline' do
        patch "/accounts/#{account.id}/pipelines/#{pipeline.id}", params: params
        expect(response).to redirect_to(account_pipeline_path(account, pipeline))
        expect(pipeline.reload.name).to eq('Updated Pipeline')
      end

      skip 'when update fails' do
        it 'renders edit with unprocessable_entity status' do
          params = { pipeline: { name: '' } }
          patch "/accounts/#{account.id}/pipelines/#{pipeline.id}", params: params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  skip 'DELETE /accounts/{account.id}/pipelines/{pipeline.id}' do
    let!(:pipeline) { create(:pipeline) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/accounts/#{account.id}/pipelines/#{pipeline.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'deletes the pipeline' do
        expect do
          delete "/accounts/#{account.id}/pipelines/#{pipeline.id}"
        end.to change(Pipeline, :count).by(-1)
        expect(response).to redirect_to(pipelines_url)
      end
    end
  end
end
