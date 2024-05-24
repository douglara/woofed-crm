class CreateDealProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :deal_products do |t|
      t.references :product, null: false, foreign_key: true
      t.references :deal, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
