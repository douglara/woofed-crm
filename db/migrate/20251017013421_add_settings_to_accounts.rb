class AddSettingsToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :settings, :jsonb, default: {}, null: false
  end
end
