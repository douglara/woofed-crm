class CreateDeals < ActiveRecord::Migration[6.1]
  def change
    create_table :deals do |t|
      t.string :name, null: false, default: ""
      t.string :status, null: false, default: "open"
      t.references :account, null: false, index: true
      t.references :stage, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.jsonb :custom_attributes, default: {}

      t.timestamps
    end
  end
end
