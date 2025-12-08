class RecreateIndexContactsChatwootId < ActiveRecord::Migration[7.1]
  def up
    remove_index :contacts, name: 'index_contacts_on_chatwoot_id'

    add_index :contacts,
               "(additional_attributes ->> 'chatwoot_id'), id",
              name: 'index_contacts_on_chatwoot_id'
  end

  def down
    remove_index :contacts, name: 'index_contacts_on_chatwoot_id'

    add_index :contacts,
              "(additional_attributes->>'chatwoot_id')",
              name: 'index_contacts_on_chatwoot_id',
              where: "additional_attributes->'chatwoot_id' IS NOT NULL"
  end
end
