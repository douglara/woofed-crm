class AddQrcodeToAppsEvolutionApis < ActiveRecord::Migration[6.1]
  def change
    add_column :apps_evolution_apis, :qrcode, :string, default: '', null: false
  end
end
