class CreateEmbeddingDocumments < ActiveRecord::Migration[6.1]
  def change
    create_table :embedding_documments do |t|
      t.references :source, polymorphic: true, null: true
      t.string :source_reference
      t.integer :status, default: 0
      t.bigint :account_id, null: false
      t.text :content
      t.vector :embedding, limit: 1536
      t.timestamps
    end
  end
end
