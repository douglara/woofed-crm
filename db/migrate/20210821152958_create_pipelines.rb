class CreatePipelines < ActiveRecord::Migration[6.1]
  def change
    create_table :pipelines do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false, default: ""

      t.timestamps
    end
  end
end
