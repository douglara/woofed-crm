class RemoveDoneFromEvents < ActiveRecord::Migration[6.1]
  def change
    remove_column :events, :done, :boolean
  end
end
