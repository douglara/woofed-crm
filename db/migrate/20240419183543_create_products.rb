class CreateProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :products do |t|
      t.string :identifier, null: false, default: ''
      t.integer :amount, null: false, default: 0
      t.integer :quantity_available, null: false, default: 0
      t.text :description, null: false, default: ''
      t.string :name, null: false, default: ''
      t.jsonb :custom_attributes, default: {}
      t.jsonb :additional_attributes, default: {}
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
