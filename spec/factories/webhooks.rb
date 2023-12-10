FactoryBot.define do
  factory :webhook do
    account
    url { 'https://woofedcrm.com' }
  end
end
