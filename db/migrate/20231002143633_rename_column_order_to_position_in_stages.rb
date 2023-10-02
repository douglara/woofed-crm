class RenameColumnOrderToPositionInStages < ActiveRecord::Migration[6.1]
  def change
    rename_column :stages, :order, :position
  end
end
