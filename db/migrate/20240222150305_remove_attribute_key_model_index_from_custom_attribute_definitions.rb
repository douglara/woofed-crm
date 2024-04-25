class RemoveAttributeKeyModelIndexFromCustomAttributeDefinitions < ActiveRecord::Migration[6.1]
  def change
    remove_index :custom_attribute_definitions, name: 'attribute_key_model_index'
  end
end
