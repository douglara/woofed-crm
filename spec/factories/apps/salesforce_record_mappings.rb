FactoryBot.define do
  factory :apps_salesforce_record_mappings, class: 'Apps::Salesforce::RecordMapping' do
    app factory: :apps_salesforces
    salesforce_object { 'Account' }
    salesforce_id { '001Hn00001AbCdEIAV' }
    recordable factory: :company
    salesforce_system_modstamp { 1.day.ago }
    last_synced_at { 1.day.ago }
    sync_status { 'synced' }

    trait :deleted do
      deleted_at { Time.current }
    end

    trait :contact do
      salesforce_object { 'Contact' }
      salesforce_id { '003Hn00002XyZwVIAV' }
      recordable factory: :contact
    end
  end
end
