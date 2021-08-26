class CreateNotes < ActiveRecord::Migration[6.1]
  def change
    create_table :notes do |t|
      t.references :flow_item, null: false, foreign_key: true

      t.timestamps
    end
  end
end
