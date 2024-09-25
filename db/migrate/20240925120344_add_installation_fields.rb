class AddInstallationFields < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :avatar_url, :string, default: '', null: false
    add_column :users, :job_description, :string, default: '', null: false
    add_column :accounts, :segment, :string, default: '', null: false
    add_column :accounts, :number_of_employees, :string, default: '', null: false
  end
end
