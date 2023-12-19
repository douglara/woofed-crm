class RenameDueToScheduledAtInEvents < ActiveRecord::Migration[6.1]
  def change
    rename_column :events, :due, :scheduled_at
  end
end
