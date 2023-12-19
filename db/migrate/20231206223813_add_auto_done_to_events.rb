class AddAutoDoneToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :auto_done, :boolean, default: false
  end
end
