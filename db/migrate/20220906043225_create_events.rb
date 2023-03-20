class CreateEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :events do |t|
      t.references :deal, null: true, index: true
      t.references :contact, null: true, index: true
      t.references :account, null: false, foreign_key: true
      # t.references :event_kind, null: false, foreign_key: true
      # t.references :record, polymorphic: true, null: false
      t.references :app, polymorphic: true, null: true

      t.string :kind, null: false, default: 'note'
      t.datetime :due, null: true
      t.boolean :done, null: true
      t.datetime :done_at, null: true
      t.boolean :from_me, null: true
      t.integer :status, default: nil
      t.jsonb :custom_attributes, default: {}
      t.jsonb :additional_attributes, default: {}

      t.timestamps
    end
  end
end
