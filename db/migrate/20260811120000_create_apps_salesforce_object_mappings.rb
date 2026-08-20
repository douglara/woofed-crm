class CreateAppsSalesforceObjectMappings < ActiveRecord::Migration[7.1]
  def change
    create_table :apps_salesforce_object_mappings do |t|
      t.references :app, null: false, foreign_key: { to_table: :apps_salesforces }
      t.string :salesforce_object, null: false
      t.string :woofed_model, null: false
      t.boolean :enabled, default: false, null: false
      # [{ "salesforce_field": "Name", "woofed_field": "name", "kind": "attribute" }, ...]
      t.jsonb :field_mappings, default: [], null: false
      # Stage map, pipeline id, SOQL filters -- whatever does not fit a flat field pair.
      t.jsonb :options, default: {}, null: false

      t.timestamps
    end

    # At most one mapping per Salesforce object: two rows for Account would leave
    # the transform with no way to choose. Enforced in the database because two
    # concurrent form submissions both pass a Rails uniqueness validation.
    #
    # app_id is redundant while a single connection exists and is kept on purpose:
    # it is what makes a second connection a UI change instead of a migration.
    add_index :apps_salesforce_object_mappings, %i[app_id salesforce_object], unique: true,
                                                                              name: 'index_salesforce_object_mappings_on_app_and_object'
  end
end
