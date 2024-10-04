class CreateVoips < ActiveRecord::Migration[7.0]
  def change
    create_table :voips do |t|
      t.references :user, null: false, index: true
      t.string :websocket_server, null: false, default: ''
      t.string :server, null: false, default: ''
      t.string :user_name, null: false, default: ''
      t.string :password, null: false, default: ''
      t.string :name, null: false, default: ''
      t.timestamps
    end
  end
end
