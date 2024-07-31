require 'rails_helper'

RSpec.describe Accounts::WebpushSubscriptionsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }

  describe 'POST /accounts/{:account.id}/webpush_subscriptions' do
    let(:valid_params) do
      {  endpoint: 'endpoint test', keys: { auth: 'auth_key', p256dh: 'p256dh_key' } }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/webpush_subscriptions"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      it 'should create webpush_subscriptions' do
        expect do
          post "/accounts/#{account.id}/webpush_subscriptions", params: valid_params
        end.to change(WebpushSubscription, :count).by(1)
      end
      context 'when webpush_subscriptions already exists from the same device' do
        let!(:webpush_subscription) { create(:webpush_subscription, user: user) }
        let(:invalid_params) do
          {  endpoint: 'endpoint test', keys: { auth: webpush_subscription.auth_key, p256dh: 'p256dh_key' } }
        end

        it 'should not create webpush_subscriptions' do
          expect do
            post "/accounts/#{account.id}/webpush_subscriptions", params: invalid_params
          end.to change(WebpushSubscription, :count).by(0)
          expect(response.body).to eq(['Auth key has already been taken'].to_json)
        end
      end
      context 'when endpoint params is blank' do
        let(:invalid_params) do
          {  endpoint: '', keys: { auth: 'auth_key', p256dh: 'p256dh_key' } }
        end
        it 'should not create webpush_subscription' do
          expect do
            post "/accounts/#{account.id}/webpush_subscriptions", params: invalid_params
          end.to change(WebpushSubscription, :count).by(0)
        end
      end
    end
  end
end
