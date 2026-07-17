class CreateDealCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :deal_companies do |t|
      t.references :deal, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end

    add_index :deal_companies, %i[deal_id company_id], unique: true
  end
end
