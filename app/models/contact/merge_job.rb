class Contact::MergeJob < ApplicationJob
  self.queue_adapter = :good_job

  def perform(base_contact_id, mergee_contact_id)
    base_contact = Contact.find_by(id: base_contact_id)
    mergee_contact = Contact.find_by(id: mergee_contact_id)

    return unless base_contact
    return unless mergee_contact

    Contact::Merge.new(base_contact:, mergee_contact:).perform
  end
end
