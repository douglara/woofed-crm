class AddIndexToContactsAdditionalAttributesChatwootId < ActiveRecord::Migration[7.1]
  def change
    add_index :contacts,
              "(additional_attributes->>'chatwoot_id')",
              name: 'index_contacts_on_chatwoot_id',
              where: "additional_attributes->'chatwoot_id' IS NOT NULL"
  end
end
