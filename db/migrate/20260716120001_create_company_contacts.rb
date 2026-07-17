class CreateCompanyContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :company_contacts do |t|
      t.references :company, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true

      t.timestamps
    end

    add_index :company_contacts, %i[company_id contact_id], unique: true
  end
end
