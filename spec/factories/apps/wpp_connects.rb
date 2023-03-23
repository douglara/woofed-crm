FactoryBot.define do
  factory :apps_wpp_connect, class: 'Apps::WppConnect' do
    name { 'Connection testing' }
    status { 'active' }
    active { true }
    session { 'session_testing' }
    token { 'token' }
    endpoint_url { 'http://localhost:3002' }
    secretkey { 'secretkey' }
    account
  end
end
