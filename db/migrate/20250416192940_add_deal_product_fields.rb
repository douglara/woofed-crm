class AddDealProductFields < ActiveRecord::Migration[7.1]
  def change
    change_table :deal_products, bulk: true do |t|
      t.bigint :unit_amount_in_cents, null: false, default: 0
      t.string :product_identifier, default: '', null: false
      t.string :product_name, default: '', null: false
      t.bigint :total_amount_in_cents, null: false, default: 0
      t.bigint :quantity, null: false, default: 1
    end
  end
end
