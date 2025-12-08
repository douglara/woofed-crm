class AddLostReasonToDeals < ActiveRecord::Migration[7.1]
  def change
    add_column :deals, :lost_reason, :string, null: false, default: ''
  end
end
