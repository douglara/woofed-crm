class CreateInstallations < ActiveRecord::Migration[7.0]
  def change
    create_table :installations, id: :string do |t|
      t.string :server_public_key
      t.string :app_private_key
      t.string :token

      t.timestamps
    end
  end
end
