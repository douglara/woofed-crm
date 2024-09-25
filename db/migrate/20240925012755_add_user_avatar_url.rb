class AddUserAvatarUrl < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :avatar_url, :string, default: '', null: false
  end
end
