class AddIndexToContactsAdditionalAttributesChatwootId < ActiveRecord::Migration[7.1]
  def change
    add_index :contacts, "(additional_attributes->>'chatwoot_id')", name: 'index_contacts_on_chatwoot_id'
  end
end
