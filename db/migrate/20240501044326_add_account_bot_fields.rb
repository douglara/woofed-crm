# frozen_string_literal: true

class AddAccountBotFields < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :site_url, :string, default: '', null: false
    add_column :accounts, :woofbot_auto_reply, :boolean, default: false, null: false
    add_column :accounts, :ai_usage, :jsonb, default: { 'tokens': 0, 'limit': 16_666_667 }, null: false
  end
end
