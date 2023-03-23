class AddStatusWppConnects < ActiveRecord::Migration[6.1]
  def change
    add_column :apps_wpp_connects, :status, :string, null: false, default: 'inactive'
  end
end
