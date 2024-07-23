class DropAppsWppConnect < ActiveRecord::Migration[6.1]
  def change
    drop_table :apps_wpp_connects
  end
end
