class AddTitleInEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :title, :string, null: false, default: ''
  end
end
