class DropUnecessaryContactsDeals < ActiveRecord::Migration[6.1]
  def change
    drop_table :contacts_deals
  end
end
