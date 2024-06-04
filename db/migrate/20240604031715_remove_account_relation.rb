class RemoveAccountRelation < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :account_id
    remove_column :webhooks, :account_id
    remove_column :stages, :account_id
    remove_column :products, :account_id
    remove_column :pipelines, :account_id
    remove_column :events, :account_id
    remove_column :deals, :account_id
    remove_column :deal_products, :account_id
    remove_column :custom_attribute_definitions, :account_id
    remove_column :contacts_deals, :account_id
    remove_column :contacts, :account_id
    remove_column :apps_wpp_connects, :account_id
    remove_column :apps_evolution_apis, :account_id
    remove_column :apps_chatwoots, :account_id
    remove_column :apps, :account_id
    remove_column :embedding_documments, :account_id
  end
end
