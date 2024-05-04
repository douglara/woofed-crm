class RenameAmountColumnInProducts < ActiveRecord::Migration[6.1]
  def change
    rename_column :products, :amount, :amount_in_cents
  end
end
