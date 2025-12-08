class UpdateAppsChatwootStatusAndRemoveActive < ActiveRecord::Migration[7.1]
  def change
    remove_column :apps_chatwoots, :active, :boolean

    change_column_default :apps_chatwoots, :status, from: 'inactive', to: 'active'

    reversible do |dir|
      dir.up do
        Apps::Chatwoot.update_all(status: 'active')
      end
      dir.down do
        Apps::Chatwoot.update_all(status: 'inactive')
      end
    end
  end
end
