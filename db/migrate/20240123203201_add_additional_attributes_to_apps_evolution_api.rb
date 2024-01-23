class AddAdditionalAttributesToAppsEvolutionApi < ActiveRecord::Migration[6.1]
  def change
    add_column :apps_evolution_apis, :additional_attributes, :jsonb
  end
end
