class CreateAttachments < ActiveRecord::Migration[6.1]
  def change
    create_table :attachments do |t|
      t.belongs_to :event, null: false, foreign_key: true
      t.integer :file_type, default: 0, null: false

      t.timestamps
    end
  end
end
