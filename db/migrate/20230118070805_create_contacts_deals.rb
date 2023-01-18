class CreateContactsDeals < ActiveRecord::Migration[6.1]
  def change
    create_table :contacts_deals do |t|
      t.references :account, index: true
      t.references :contact, index: true
      t.references :deal, index: true
      t.boolean :main, default: true, null: false
    end

    add_index :contacts_deals, [:contact_id, :deal_id], unique: true, name: 'contact_deal_index'
  end
end
