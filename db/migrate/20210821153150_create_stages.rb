class CreateStages < ActiveRecord::Migration[6.1]
  def change
    create_table :stages do |t|
      t.string :name, null: false, default: ""
      t.references :account, null: false, index: true
      t.references :pipeline, null: false, foreign_key: true
      t.integer :order, null: false, default: 1

      t.timestamps
    end
  end
end
