class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies do |t|
      t.string :name, default: '', null: false
      t.string :phone, default: '', null: false
      t.string :email, default: '', null: false
      t.jsonb :custom_attributes, default: {}
      t.jsonb :additional_attributes, default: {}

      t.timestamps
    end

    # NULLIF lets any number of companies keep the '' default, while a filled in
    # email/phone stays unique. Mirrors the contacts indexes.
    add_index :companies, "LOWER(NULLIF(email, ''))", unique: true, name: 'index_companies_on_lower_email'
    add_index :companies, "NULLIF(phone, '')", unique: true, name: 'index_companies_on_phone'
  end
end
