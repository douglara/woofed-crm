class ChangeUserNotificationsDefaultValue < ActiveRecord::Migration[7.0]
  def change
    change_column_default :users, :notifications, { "webpush_notify_on_event_expired": false }.to_json
  end
end
