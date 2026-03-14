class CreatePlugins < ActiveRecord::Migration[7.1]
  def change
    create_table :plugins do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.text :prompt, null: false
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end
  end
end
