class CreateWebpushSubscriptions < ActiveRecord::Migration[6.1]
  def change
    create_table :webpush_subscriptions do |t|
      t.string :endpoint, null: false, default: ''
      t.string :auth_key, null: false, default: ''
      t.string :p256dh_key, null: false, default: ''
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
