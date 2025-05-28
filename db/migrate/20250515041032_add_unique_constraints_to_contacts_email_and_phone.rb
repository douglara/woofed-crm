class AddUniqueConstraintsToContactsEmailAndPhone < ActiveRecord::Migration[7.1]
  def change
    Contact::Migrations::MergeDuplicateContactsJob.perform_now
    add_index :contacts, "LOWER(NULLIF(email, ''))", unique: true, name: 'index_contacts_on_lower_email'
    add_index :contacts, "NULLIF(phone, '')", unique: true, name: 'index_contacts_on_phone'
  end
end
