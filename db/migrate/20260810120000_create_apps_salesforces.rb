class CreateAppsSalesforces < ActiveRecord::Migration[7.1]
  def change
    create_table :apps_salesforces do |t|
      t.string :name, default: '', null: false
      t.string :status, default: 'inactive', null: false
      t.string :environment, default: 'production', null: false
      t.string :client_id, default: '', null: false
      t.string :instance_url, default: '', null: false
      t.string :organization_id, default: '', null: false
      t.string :api_version, default: 'v64.0', null: false
      t.datetime :token_expires_at
      t.jsonb :settings, default: {}, null: false

      # Encrypted columns are text: the ciphertext envelope is several times
      # longer than the plaintext it replaces.
      t.text :client_secret
      t.text :access_token
      t.text :refresh_token

      t.timestamps
    end
  end
end
