class AddStatusToWebhooks < ActiveRecord::Migration[6.1]
  def change
    add_column :webhooks, :status, :string, default: 'active'
  end
end
