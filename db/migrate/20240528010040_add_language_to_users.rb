class AddLanguageToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :language, :string, default: 'en', null: false
  end
end
