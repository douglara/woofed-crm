require 'rails_helper'

RSpec.describe 'Chatwoot install_widget', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:chatwoot) { create(:apps_chatwoots, :skip_validate, account:, embedding_token: 'tok123') }

  before { sign_in(user) }

  it 'runs the injection with the given super-admin credentials and redirects with a notice' do
    allow(Accounts::Apps::Chatwoots::InjectDashboardScript).to receive(:call).and_return(ok: true)

    post "/accounts/#{account.id}/apps/chatwoots/#{chatwoot.id}/install_widget",
         params: { super_admin_email: 'admin@test.com', super_admin_password: 'secret' }

    expect(response).to redirect_to(edit_account_apps_chatwoot_path(account, chatwoot))
    expect(flash[:notice]).to be_present
    expect(Accounts::Apps::Chatwoots::InjectDashboardScript).to have_received(:call)
      .with(hash_including(super_admin_email: 'admin@test.com', super_admin_password: 'secret'))
  end

  it 'redirects with an alert when the injection fails' do
    allow(Accounts::Apps::Chatwoots::InjectDashboardScript).to receive(:call).and_return(error: 'unauthorized')

    post "/accounts/#{account.id}/apps/chatwoots/#{chatwoot.id}/install_widget",
         params: { super_admin_email: 'admin@test.com', super_admin_password: 'wrong' }

    expect(response).to redirect_to(edit_account_apps_chatwoot_path(account, chatwoot))
    expect(flash[:alert]).to include('unauthorized')
  end
end
