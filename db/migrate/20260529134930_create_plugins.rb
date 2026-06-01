class CreatePlugins < ActiveRecord::Migration[7.1]
  def change
    create_table :plugins, id: :string do |t|
      t.string  :name, null: false
      t.string  :status, null: false, default: "active" # active/inactive/failed
      t.string  :version        # semver read from the manifest
      t.integer :priority, null: false, default: 0

      t.timestamps
    end

    add_index :plugins, :status
  end
end
