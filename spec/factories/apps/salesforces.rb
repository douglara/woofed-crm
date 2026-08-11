FactoryBot.define do
  factory :apps_salesforces, class: 'Apps::Salesforce' do
    name { 'Salesforce' }
    client_id { 'consumer-key' }
    client_secret { 'consumer-secret' }

    trait :connected do
      status { 'active' }
      instance_url { 'https://woofed-dev-ed.my.salesforce.com' }
      organization_id { '00D5g000000XXXXEA0' }
      access_token { 'access-token' }
      refresh_token { 'refresh-token' }
      token_expires_at { 2.hours.from_now }
    end

    trait :sandbox do
      environment { 'sandbox' }
    end

    trait :token_expired do
      token_expires_at { 1.minute.ago }
    end
  end
end
