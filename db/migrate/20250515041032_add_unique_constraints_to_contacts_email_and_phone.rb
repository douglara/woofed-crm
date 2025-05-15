class AddUniqueConstraintsToContactsEmailAndPhone < ActiveRecord::Migration[7.1]
  def change
    add_index :contacts, 'LOWER(email)', unique: true, name: 'index_contacts_on_lower_email'
    add_index :contacts, :phone, unique: true, name: 'index_contacts_on_phone'
  end
end
