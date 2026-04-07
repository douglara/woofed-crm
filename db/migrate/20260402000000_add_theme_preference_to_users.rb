class AddThemePreferenceToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :theme_preference, :string, default: 'system', null: false
  end
end
