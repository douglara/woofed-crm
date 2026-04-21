class AddColorToStages < ActiveRecord::Migration[7.1]
  def change
    add_column :stages, :color, :string, default: '#6857D9', null: false
  end
end
