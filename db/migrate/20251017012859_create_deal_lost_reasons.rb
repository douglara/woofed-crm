class CreateDealLostReasons < ActiveRecord::Migration[7.1]
  def change
    create_table :deal_lost_reasons do |t|
      t.string :name, default: '', null: false

      t.timestamps
    end
  end
end
