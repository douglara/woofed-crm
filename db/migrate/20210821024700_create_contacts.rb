class CreateContacts < ActiveRecord::Migration[6.1]
  def change
    create_table :contacts do |t|
      t.references :account, null: false, index: true
      t.string :full_name, null: false, default: ""
      t.string :phone, null: false, default: ""
      t.string :email, null: false, default: ""
      t.jsonb :custom_attributes, default: {}
      t.timestamps
    end
  end
end
