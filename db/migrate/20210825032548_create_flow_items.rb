class CreateFlowItems < ActiveRecord::Migration[6.1]
  def change
    create_table :flow_items do |t|
      t.string :kind, null: false, default: ""
      t.references :deal, null: false, foreign_key: true

      t.timestamps
    end
  end
end
