require 'set'

class Contact::Migrations::MergeDuplicateContacts
  def initialize(enqueue: false)
    @enqueue = enqueue
  end

  def call
    email_groups = group_duplicate_contacts_by_email
    phone_groups = group_duplicate_contacts_by_phone

    return nil if email_groups.empty? && phone_groups.empty?

    merge_process(email_groups, phone_groups)
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


  def merge_process(email_groups, phone_groups)
    processed_contact_ids = Set.new

    email_groups.each do |contact_ids|
      next if contact_ids.size < 2 || processed_contact_ids.superset?(contact_ids.to_set)
      merge_group(contact_ids)
      processed_contact_ids.merge(contact_ids)
    end

    phone_groups.each do |contact_ids|
      next if contact_ids.size < 2 || processed_contact_ids.superset?(contact_ids.to_set)
      merge_group(contact_ids)
      processed_contact_ids.merge(contact_ids)
    end
  end

  def merge_group(contact_ids)
    contacts = Contact.where(id: contact_ids).order(:id).to_a
    return if contacts.size < 2

    base_contact = contacts.shift
    contacts.each do |mergee_contact|
      begin
        if @enqueue
          Contact::MergeJob.set(queue: 'migration').perform_later(base_contact.id, mergee_contact.id)
        else
          Contact::Merge.new(base_contact:, mergee_contact:).perform
        end
      rescue StandardError => e
        Rails.logger.error("Failed to merge contact #{mergee_contact.id} into #{base_contact.id}: #{e.message}")
      end
    end
  end
end
