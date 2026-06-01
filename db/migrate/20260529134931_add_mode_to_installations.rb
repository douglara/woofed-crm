class AddModeToInstallations < ActiveRecord::Migration[7.1]
  def change
    add_column :installations, :mode, :string, null: false, default: "safe"
  end
end
