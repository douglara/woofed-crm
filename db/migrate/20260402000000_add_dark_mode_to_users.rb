class AddDarkModeToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :dark_mode, :boolean, default: false, null: false
  end
end
