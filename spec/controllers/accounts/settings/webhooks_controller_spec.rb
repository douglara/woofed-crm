require 'rails_helper'

RSpec.describe Accounts::Settings::WebhooksController, type: :request do
    let!(:account) { create(:account) }
    let!(:user) { create(:user, account: account) }
    let!(:webhook) { create(:webhook, account: account) }

    describe 'POST /accounts/{account.id}/webhooks' do
        let(:valid_params) { { webhook: { url: 'testeurl.com.br' } } }

        context 'when it is an unauthenticated user' do
        it 'returns unauthorized' do
            post "/accounts/#{account.id}/webhooks" 
            expect(response).to redirect_to(new_user_session_path)
        end
        end

        context 'when it is an authenticated user' do
        before do
            sign_in(user)
        end

        context 'create webhook' do
            it do
            expect do
                post "/accounts/#{account.id}/webhooks",
                params: valid_params
            end.to change(Webhook, :count).by(1)
            expect(response).to redirect_to(account_webhooks_path(account))
            end
            context 'when url is invalid' do
                it 'when url is blank' do
                invalid_params = { webhook: { url: ''}}
                expect do
                    post "/accounts/#{account.id}/webhooks",
                    params: invalid_params
                end.to change(Webhook, :count).by(0)
                expect(response.body).to include("Url não pode ficar em branco")
                expect(response).to have_http_status(:unprocessable_entity)
                end
            end
        end
        end
    end
    describe 'GET /accounts/{account.id}/webhooks' do

        context 'when it is an unauthenticated user' do
        it 'returns unauthorized' do
            get "/accounts/#{account.id}/webhooks" 
            expect(response).to redirect_to(new_user_session_path)
        end
        end

        context 'when it is an authenticated user' do
        before do
            sign_in(user)
        end

        context 'get webhooks' do
            it do
                get "/accounts/#{account.id}/webhooks"
                expect(response.body).to include("https://woofedcrm.com")
                expect(response).to have_http_status(200)
            end
            it 'get webhooks by account' do
            account_2 = create(:account, name: 'account teste')
            create(:webhook, url: 'teste-url.com.br', account_id: account_2.id)
            get "/accounts/#{account.id}/webhooks"
            expect(response.body).to include("https://woofedcrm.com")
            expect(account.webhooks.count).to eq(1)
            end
        end
        end
    end
    describe 'PACTH /accounts/{account.id}/users/{webhook.id}' do

        context 'when it is an unauthenticated user' do
        it 'returns unauthorized' do
            patch "/accounts/#{account.id}/webhooks/#{webhook.id}" 
            expect(response).to redirect_to(new_user_session_path)
        end
        end

        context 'when it is an authenticated user' do
            before do
                sign_in(user)
            end

            context 'update webhook' do
                let(:valid_params) { { webhook: {url: 'www.url-updated.com.br'} } }
                it do
                    patch "/accounts/#{account.id}/webhooks/#{webhook.id}", params: valid_params
                    expect(Webhook.first.url).to eq('www.url-updated.com.br')
                    expect(response.body).to redirect_to(edit_account_webhook_path(account.id, webhook.id))
                end
                context 'when url is invalid' do
                    it 'when url is blank' do
                        invalid_params = { webhook: {url: '' } }

                        patch "/accounts/#{account.id}/webhooks/#{webhook.id}",
                        params: invalid_params
                        expect(Webhook.first.url).to eq('https://woofedcrm.com')
                        expect(response.body).to include("Url não pode ficar em branco")
                        expect(response).to have_http_status(:unprocessable_entity)
                    end
                end
            end
        end
    end
  describe "DELETE /accounts/{account.id}/webhooks/{webhook.id}" do
        context 'when it is an unauthenticated user' do
            it 'returns unauthorized' do
            delete "/accounts/#{account.id}/webhooks/#{webhook.id}" 
            expect(response).to redirect_to(new_user_session_path)
            end
        end
        context 'when it is an authenticated user' do
            before do
                sign_in(user)
            end
            context 'delete the user' do
                it do
                    delete "/accounts/#{account.id}/webhooks/#{webhook.id}"
                    expect(Webhook.count).to eq(0)
                    expect(response.status).to eq(204)
                end
            end
        end
    end   
end