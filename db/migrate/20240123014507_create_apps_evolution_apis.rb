class CreateAppsEvolutionApis < ActiveRecord::Migration[6.1]
  def change
    create_table :apps_evolution_apis do |t|
      t.references :account, null: false, foreign_key: true
      t.string :connection_status, null: false, default: 'inactive'
      t.boolean :active, null: false, default: 'active'
      t.string :endpoint_url, null: false, default: ''
      t.string :token, null: false, default: ''
      t.string :phone, null: false, default: ''
      t.string :name, null: false, default: ''
      t.string :instance, null: false, default: ''
      t.jsonb :additional_attributes, default: {}

      t.timestamps
    end
  end
end
