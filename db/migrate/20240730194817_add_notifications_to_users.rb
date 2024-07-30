class AddNotificationsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :notifications, :jsonb, null: false, default: {}
  end
end
