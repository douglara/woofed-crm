class CreateFlowItemsActivitiesKindsWpConnects < ActiveRecord::Migration[6.1]
  def change
    create_table :flow_items_activities_kinds_wp_connects do |t|
      t.string :name, null: false, default: ""
      t.boolean :enabled, null: false, default: false
      t.string :secretkey, null: false, default: ""
      t.string :endpoint_url, null: false, default: ""
      t.string :session, null: false, default: ""
      t.string :token, null: false, default: ""

      t.timestamps
    end
  end
end
