FactoryBot.define do
  factory :apps_chatwoots, class: 'Apps::Chatwoot' do
    name { 'Connection testing' }
    status { 'active' }
    active { true }
    chatwoot_endpoint_url { ENV['CHATWOOT_ENDPOINT'] || 'http://localhost:3000' }
    chatwoot_user_token { ENV['CHATWOOT_TOKEN'] || 'token' }
    embedding_token { 'http://localhost:3002' }
    chatwoot_account_id { '5' }
    chatwoot_dashboard_app_id { '1' }
    chatwoot_webhook_id { '1' }
    account

    trait :skip_validate do
      to_create {|instance| instance.save(validate: false)}
    end
  end
end