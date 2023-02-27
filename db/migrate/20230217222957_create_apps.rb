class CreateApps < ActiveRecord::Migration[6.1]
  def change
    create_table :apps do |t|
      t.references :account, index: true
      t.string :name
      t.string :kind
      t.boolean :active, null: false, default: false
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end
  end
end
