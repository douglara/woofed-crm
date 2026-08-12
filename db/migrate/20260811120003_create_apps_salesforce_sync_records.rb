class CreateAppsSalesforceSyncRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :apps_salesforce_sync_records do |t|
      t.references :app, null: false, foreign_key: { to_table: :apps_salesforces }
      t.references :sync_run, foreign_key: { to_table: :apps_salesforce_sync_runs }
      t.string :salesforce_object, null: false
      t.string :salesforce_id, null: false
      # The raw row exactly as Salesforce sent it, persisted before mapping so a
      # changed field mapping re-runs the transform locally instead of downloading
      # the org again -- api calls are the customer's metered resource.
      t.jsonb :payload, default: {}, null: false
      # pending / processed / failed / conflict. A conflicting row keeps its
      # reason here, which is what the conflicts screen lists.
      t.string :status, default: 'pending', null: false
      t.text :error
      t.datetime :processed_at

      t.timestamps
    end

    add_index :apps_salesforce_sync_records, %i[app_id status],
              name: 'index_salesforce_sync_records_on_app_and_status'
    add_index :apps_salesforce_sync_records, %i[app_id salesforce_object salesforce_id],
              name: 'index_salesforce_sync_records_on_app_object_and_id'
  end
end
