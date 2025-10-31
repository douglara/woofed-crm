class AddFieldsToPipelinesAndStages < ActiveRecord::Migration[7.1]
  def change
    add_column :pipelines, :active, :boolean, default: true, null: false
    add_column :stages, :background_color, :string, default: "#FFFFFF"
    add_column :stages, :text_color, :string, default: "#000000"
  end
end
