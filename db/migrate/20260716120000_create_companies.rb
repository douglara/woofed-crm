class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies do |t|
      t.string :name, default: '', null: false
      t.string :phone, default: '', null: false
      t.string :email, default: '', null: false
      t.jsonb :custom_attributes, default: {}
      t.jsonb :additional_attributes, default: {}

      t.timestamps
    end
  end
end
