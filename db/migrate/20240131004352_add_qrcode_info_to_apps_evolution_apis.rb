class AddQrcodeInfoToAppsEvolutionApis < ActiveRecord::Migration[6.1]
  def change
    add_column :apps_evolution_apis, :qrcode_info, :jsonb, default: {}
  end
end
