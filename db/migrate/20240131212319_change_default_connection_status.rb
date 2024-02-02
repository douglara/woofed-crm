class ChangeDefaultConnectionStatus < ActiveRecord::Migration[6.1]
  def change
    change_column_default :apps_evolution_apis, :connection_status, 'disconnected'
  end
end
