class CreateWebhooks < ActiveRecord::Migration[6.1]
  def change
    create_table :webhooks do |t|
      t.references :account, index: true
      t.string :url, default: '', null: false

      t.timestamps
    end
  end
end
