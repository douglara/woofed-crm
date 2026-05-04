class AddDeviseTrackableColumnsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :sign_in_count, :integer, default: 0
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string

    add_column :users, :failed_attempts, :integer, default: 0
    add_column :users, :unlock_token, :string
    add_column :users, :locked_at, :datetime
    add_index :users, :unlock_token, unique: true
  end
end
