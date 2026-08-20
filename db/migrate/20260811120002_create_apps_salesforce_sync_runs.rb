class CreateAppsSalesforceSyncRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :apps_salesforce_sync_runs do |t|
      t.references :app, null: false, foreign_key: { to_table: :apps_salesforces }
      t.string :salesforce_object, null: false
      t.string :kind, default: 'backfill', null: false
      t.string :status, default: 'pending', null: false
      # Bulk job state. Stored rather than carried in job arguments so a retry
      # polls the existing job instead of creating a second one on the org.
      t.string :bulk_job_id
      t.string :locator
      # High-water mark: max(SystemModstamp) seen, where the next delta starts.
      t.datetime :cursor
      t.bigint :records_downloaded, default: 0, null: false
      t.bigint :records_failed, default: 0, null: false
      t.datetime :started_at
      t.datetime :finished_at
      t.text :error

      t.timestamps
    end

    add_index :apps_salesforce_sync_runs, %i[app_id salesforce_object status],
              name: 'index_salesforce_sync_runs_on_app_object_and_status'
  end
end
