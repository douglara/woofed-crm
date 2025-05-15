class EnqueueMergeDuplicateContacts < ActiveRecord::Migration[7.1]
  def change
    processed_groups = Contact::Migrations::MergeDuplicateContacts.new(enqueue: true).call
    Rails.logger.info("Enqueued #{processed_groups} groups of duplicate contacts for merging")
  end
end
