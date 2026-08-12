FactoryBot.define do
  factory :apps_salesforce_sync_runs, class: 'Apps::Salesforce::SyncRun' do
    app factory: :apps_salesforces
    salesforce_object { 'Account' }
    kind { 'backfill' }
    status { 'pending' }

    trait :running do
      status { 'running' }
      started_at { 1.minute.ago }
      bulk_job_id { '750Hn00000AbCdEIAV' }
    end

    trait :delta do
      kind { 'delta' }
      cursor { 1.hour.ago }
    end
  end
end
