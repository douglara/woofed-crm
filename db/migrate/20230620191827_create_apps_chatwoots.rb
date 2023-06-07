class CreateAppsChatwoots < ActiveRecord::Migration[6.1]
  def change
    create_table :apps_chatwoots do |t|
      t.references :account, index: true
      t.string :name
      t.boolean :active, null: false, default: false

      t.string :endpoint_url, null: false, default: ''
      t.string :user_token, null: false, default: ''
      t.string :embedding_token, null: false, default: ''

      t.timestamps
    end
  end
end
