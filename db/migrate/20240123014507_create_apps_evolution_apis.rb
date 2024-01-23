class CreateAppsEvolutionApis < ActiveRecord::Migration[6.1]
  def change
    create_table :apps_evolution_apis do |t|
      t.references :account, null: false, foreign_key: true
      t.string :status
      t.boolean :active
      t.string :endpoint_url
      t.string :token
      t.string :phone
      t.string :name

      t.timestamps
    end
  end
end
