class ChangeDefaultValuesToAccountsAndUsers < ActiveRecord::Migration[7.0]
  def change
    change_column_default :users, :job_description, 'other'
    change_column_default :accounts, :segment, 'other'
    change_column_default :accounts, :number_of_employees, '1-10'
  end
end
