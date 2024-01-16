class RemoveDefaultKindEventValue < ActiveRecord::Migration[6.1]
  def change
    change_column_default :events, :kind, nil
  end
end
