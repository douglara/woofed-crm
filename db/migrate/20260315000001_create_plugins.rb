class CreatePlugins < ActiveRecord::Migration[7.1]
  def change
    create_table :plugins do |t|
      t.string :name, null: false
      t.string :github_url
      t.string :status, null: false, default: 'active'
      t.string :version
      t.string :commit_sha

      t.timestamps
    end

    add_index :plugins, :name, unique: true
  end
end
