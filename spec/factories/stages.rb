FactoryBot.define do
  factory :stage do
    account
    pipeline
    name { 'Stage 1' }
  end
end
