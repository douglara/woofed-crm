class CreateAppsChatwoots < ActiveRecord::Migration[6.1]
  def change
    create_table :apps_chatwoots do |t|
      t.references :account, index: true
      t.string :name
      t.boolean :active, null: false, default: false

      t.string :status, null: false, default: 'inactive'
      t.string :embedding_token, null: false, default: ''
      t.integer :chatwoot_account_id, null: false
      t.string :chatwoot_endpoint_url, null: false, default: ''
      t.string :chatwoot_user_token, null: false, default: ''
      t.integer :chatwoot_dashboard_app_id, null: false
      t.integer :chatwoot_webhook_id, null: false

      t.timestamps
    end
  end
end
