# == Schema Information
#
# Table name: apps_salesforces
#
#  id               :bigint           not null, primary key
#  access_token     :text
#  api_version      :string           default("v64.0"), not null
#  client_secret    :text
#  environment      :string           default("production"), not null
#  instance_url     :string           default(""), not null
#  name             :string           default(""), not null
#  refresh_token    :text
#  settings         :jsonb            not null
#  status           :string           default("inactive"), not null
#  token_expires_at :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  client_id        :string           default(""), not null
#  organization_id  :string           default(""), not null
#
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
