class AddWebpushNotifyOnEventCompletionToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :webpush_notify_on_event_completion, :boolean, default: false, null: false
  end
end
