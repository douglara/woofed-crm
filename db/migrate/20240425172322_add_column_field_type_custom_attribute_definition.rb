class AddColumnFieldTypeCustomAttributeDefinition < ActiveRecord::Migration[6.1]
  def change
    add_column :custom_attribute_definitions, :attribute_type_field, :integer, default: 0
    add_column :custom_attribute_definitions, :attribute_options_select, :string
  end
end
