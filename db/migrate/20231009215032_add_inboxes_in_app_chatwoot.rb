class AddInboxesInAppChatwoot < ActiveRecord::Migration[6.1]
  def change
    add_column :apps_chatwoots, :inboxes, :jsonb, null: false, default: []
  end
end
