class DropUnecessaryTables < ActiveRecord::Migration[6.1]
  def change
    drop_table :activities
    drop_table :flow_items
    drop_table :notes
  end
end
