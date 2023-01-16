class CreateCustomAttributeDefinitions < ActiveRecord::Migration[6.1]
  def change
    create_table :custom_attribute_definitions do |t|
      t.integer "attribute_model", default: 0
      t.string "attribute_key"
      t.string "attribute_display_name"
      t.text "attribute_description"

      t.references :account, index: true
      t.timestamps
    end

    add_index :custom_attribute_definitions, [:attribute_key, :attribute_model], unique: true, name: 'attribute_key_model_index'
  end
end
