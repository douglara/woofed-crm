class CreateActivities < ActiveRecord::Migration[6.1]
  def change
    create_table :activities do |t|
      t.string :name, null: false, default: ""
      t.datetime :due
      t.boolean :done, null: false, default: false

      # t.references :activity_kind, null: false, foreign_key: true

      t.timestamps
    end
  end
end
