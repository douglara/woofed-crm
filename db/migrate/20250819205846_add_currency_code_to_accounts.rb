class AddCurrencyCodeToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :currency_code, :string, null: false, default: 'BRL'
  end
end
