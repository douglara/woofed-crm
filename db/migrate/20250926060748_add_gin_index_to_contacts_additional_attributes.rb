class AddGinIndexToContactsAdditionalAttributes < ActiveRecord::Migration[7.1]
  def change
    add_index :contacts, :additional_attributes, using: :gin, name: 'index_contacts_on_additional_attributes_gin'
  end
end
