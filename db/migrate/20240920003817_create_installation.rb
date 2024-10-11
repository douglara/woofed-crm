class CreateInstallation < ActiveRecord::Migration[7.0]
  def change
    create_table :installations, id: :string do |t|
      t.string :key1, null: false, default: ''
      t.string :key2, null: false, default: ''
      t.string :token, null: false, default: ''
      t.integer :status, null: false, default: 0
      t.references :user, null: true
      t.timestamps
    end
  end
end
