class CreateActivityKinds < ActiveRecord::Migration[6.1]
  def change
    create_table :activity_kinds do |t|
      t.string :name, null: false, default: ""
      t.string :key, null: false, default: ""
      t.integer :order, null: false, default: 0
      t.string :icon_key, null: false, default: ""
      t.boolean :enabled, null: false, default: false
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end
  end
end
