class AddLostAtAndWonAtToDeals < ActiveRecord::Migration[7.1]
  def change
    add_column :deals, :lost_at, :datetime
    add_column :deals, :won_at, :datetime
  end
end
