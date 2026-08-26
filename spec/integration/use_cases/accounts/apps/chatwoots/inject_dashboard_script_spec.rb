require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::InjectDashboardScript, type: :request do
  let(:chatwoot) { create(:apps_chatwoots, :skip_validate, chatwoot_endpoint_url: 'http://chat.test') }
  let(:script) { '<script src="https://crm.test/apps/chatwoots/dashboard_script?token=t"></script>' }

  def stub_sign_in_page
    stub_request(:get, 'http://chat.test/super_admin/sign_in')
      .to_return(status: 200, body: '<meta name="csrf-token" content="csrf1">',
                 headers: { 'Set-Cookie' => '_cw_session=abc; path=/; HttpOnly' })
  end

  it 'returns missing_credentials when credentials are blank' do
    result = described_class.call(chatwoot:, super_admin_email: nil, super_admin_password: nil, script:)
    expect(result).to eq(error: 'missing_credentials')
  end

  it 'signs in, finds the DASHBOARD_SCRIPTS config and patches it' do
    stub_sign_in_page
    stub_request(:post, 'http://chat.test/super_admin/sign_in')
      .to_return(status: 302, headers: { 'Set-Cookie' => '_cw_session=auth; path=/; HttpOnly' })
    stub_request(:get, 'http://chat.test/super_admin/installation_configs?search=DASHBOARD_SCRIPTS')
      .to_return(status: 200, body: '<a href="/super_admin/installation_configs/7/edit">DASHBOARD_SCRIPTS</a>')
    stub_request(:get, 'http://chat.test/super_admin/installation_configs/7/edit')
      .to_return(status: 200, body: '<meta name="csrf-token" content="csrf2">')
    stub_request(:post, 'http://chat.test/super_admin/installation_configs/7').to_return(status: 302)

    result = described_class.call(chatwoot:, super_admin_email: 'admin@test.com', super_admin_password: 'secret', script:)

    expect(result).to eq(ok: true)
    expect(WebMock).to have_requested(:post, 'http://chat.test/super_admin/sign_in')
      .with(body: hash_including('super_admin' => hash_including('email' => 'admin@test.com')))
    expect(WebMock).to have_requested(:post, 'http://chat.test/super_admin/installation_configs/7')
      .with { |req| req.body.include?('installation_config%5Bvalue%5D') && req.body.include?('_method=patch') }
  end

  it 'returns config_not_found when the config id is absent' do
    stub_sign_in_page
    stub_request(:post, 'http://chat.test/super_admin/sign_in').to_return(status: 302)
    stub_request(:get, 'http://chat.test/super_admin/installation_configs?search=DASHBOARD_SCRIPTS')
      .to_return(status: 200, body: 'no configs here')

    result = described_class.call(chatwoot:, super_admin_email: 'admin@test.com', super_admin_password: 'secret', script:)
    expect(result).to eq(error: 'config_not_found')
  end

  it 'degrades to an error hash (never raises) on network failure' do
    stub_request(:get, 'http://chat.test/super_admin/sign_in').to_timeout

    result = described_class.call(chatwoot:, super_admin_email: 'admin@test.com', super_admin_password: 'secret', script:)
    expect(result).to have_key(:error)
  end
end
