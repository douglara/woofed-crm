class CreateAppsSalesforceRecordMappings < ActiveRecord::Migration[7.1]
  def change
    create_table :apps_salesforce_record_mappings do |t|
      t.references :app, null: false, foreign_key: { to_table: :apps_salesforces }
      # The Salesforce end of the bridge. The object is stored rather than derived
      # from the id prefix, because custom objects have per-org prefixes.
      t.string :salesforce_id, null: false
      t.string :salesforce_object, null: false
      # The Woofed end: Company, Contact, Deal or Event.
      t.references :recordable, polymorphic: true, null: false
      # Last seen remote modification, used to skip records that did not change.
      t.datetime :salesforce_system_modstamp
      t.datetime :last_synced_at
      t.string :sync_status, default: 'pending', null: false
      t.text :sync_error
      # Set when the Salesforce record is deleted. The Woofed record survives,
      # because it may have accumulated local data the user does not want to lose.
      t.datetime :deleted_at

      t.timestamps
    end

    # Contact and Lead both map onto a Woofed Contact, so the object is part of
    # the identity: only the pair identifies a record on the Salesforce side.
    add_index :apps_salesforce_record_mappings, %i[app_id salesforce_object salesforce_id], unique: true,
                                                                                            name: 'index_salesforce_record_mappings_on_app_object_and_id'
  end
end
