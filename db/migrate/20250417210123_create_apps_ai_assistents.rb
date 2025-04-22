class CreateAppsAiAssistents < ActiveRecord::Migration[7.1]
  def change
    create_table :apps_ai_assistents do |t|
      t.boolean :enabled, default: false, null: false
      t.string :api_key, default: '', null: false
      t.string :model, default: 'gpt-4o', null: false
      t.boolean :auto_reply, default: false, null: false
      t.jsonb :usage, default: { 'tokens': 0 }, null: false

      t.timestamps
    end
  end
end
