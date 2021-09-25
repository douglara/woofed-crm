class CreateFlowItems < ActiveRecord::Migration[6.1]
  def change
    create_table :flow_items do |t|
      t.references :deal, null: true, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.references :kind, null: true, polymorphic: true, index: false
      t.jsonb :item

      t.timestamps
    end
  end
end
