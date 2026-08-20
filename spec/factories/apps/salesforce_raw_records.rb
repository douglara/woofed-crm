FactoryBot.define do
  factory :apps_salesforce_raw_records, class: 'Apps::Salesforce::RawRecord' do
    app factory: :apps_salesforces
    salesforce_object { 'Account' }
    salesforce_id { '001Hn00001AbCdEIAV' }
    payload do
      { 'Id' => '001Hn00001AbCdEIAV', 'Name' => 'Acme Ltda', 'SystemModstamp' => '2026-08-01T14:22:31.000Z' }
    end
    status { 'pending' }

    trait :processed do
      status { 'processed' }
      processed_at { Time.current }
    end

    trait :conflict do
      status { 'conflict' }
      processed_at { Time.current }
      error { 'Email already belongs to another contact' }
    end
  end
end
