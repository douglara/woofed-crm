class Contact::Migrations::MergeDuplicateContactsJob < ApplicationJob
  self.queue_adapter = :good_job

  def perform
    phone_groups = group_duplicate_contacts_by_phone

    merge_process(phone_groups) if phone_groups.present?

    email_groups = group_duplicate_contacts_by_email

    merge_process(email_groups) if email_groups.present?
  end

  private

  def group_duplicate_contacts_by_email
    Contact.where.not(email: [nil, ''])
                               .group(:email)
                               .having('COUNT(*) > 1')
                               .pluck(:email)
                               .map { |email| Contact.where(email:).order(:id).pluck(:id) }
  end

  def group_duplicate_contacts_by_phone
    Contact.where.not(phone: [nil, ''])
                               .group(:phone)
                               .having('COUNT(*) > 1')
                               .pluck(:phone)
                               .map { |phone| Contact.where(phone:).order(:id).pluck(:id) }
  end


  def merge_process(contact_groups)
    contact_groups.each do |contact_ids|
      next if contact_ids.size < 2
      merge_group(contact_ids)
    end
  end

  def merge_group(contact_ids)
    contacts = Contact.where(id: contact_ids).order(:id).to_a
    return if contacts.size < 2

    base_contact = contacts.shift
    base_contact.skip_validation = true
 
    contacts.each do |mergee_contact|
      Contact::Merge.new(base_contact:, mergee_contact:).perform
    end
  end
end
