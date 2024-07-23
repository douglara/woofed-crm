class DropWppConnectTables < ActiveRecord::Migration[6.1]
  def change
    drop_table :apps_wpp_connects
    drop_table :wp_connects
  end
end
