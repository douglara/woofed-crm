class AddPositionToDeals < ActiveRecord::Migration[6.1]
  def change
    add_column :deals, :position, :integer, null: false, default: 1
  end
end
