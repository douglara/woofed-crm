class CreateAppsWppConnects < ActiveRecord::Migration[6.1]
  def change
    create_table :apps_wpp_connects do |t|
      t.references :account, index: true
      t.string :name
      t.boolean :active, null: false, default: false


      t.string :session, null: false, default: ''
      t.string :token, null: false, default: ''
      t.string :endpoint_url, null: false, default: ''
      t.string :secretkey, null: false, default: ''

      t.timestamps
    end
  end
end
