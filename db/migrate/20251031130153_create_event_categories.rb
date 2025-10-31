class CreateEventCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :event_categories do |t|
      t.string :name, null: false, default: ""
      t.string :icon, null: false, default: ""
      t.string :color, null: false, default: "#6857D9"
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
