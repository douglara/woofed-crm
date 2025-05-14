class Contact::Merge
  MERGEABLE_KEYS = %w[full_name email phone additional_attributes custom_attributes].freeze

  def initialize(base_contact:, mergee_contact:)
    raise ArgumentError, 'base_contact is required' unless base_contact
    raise ArgumentError, 'mergee_contact is required' unless mergee_contact

    @base_contact = base_contact
    @mergee_contact = mergee_contact
  end

  def perform
    ActiveRecord::Base.transaction do
      validate_contacts
      merge_deals
      merge_events
      merge_and_remove_mergee_contact
    end
    @base_contact
  end

  private

  def validate_contacts
    return if @base_contact != @mergee_contact

    raise StandardError, 'contact does merge with same contact'
  end

  def merge_deals
    Deal.where(contact_id: @mergee_contact.id).update_all(contact_id: @base_contact.id)
  end

  def merge_events
    Event.where(contact_id: @mergee_contact.id).update_all(contact_id: @base_contact.id)
  end

  def merge_and_remove_mergee_contact
    base_attrs   = @base_contact.attributes.slice(*MERGEABLE_KEYS).compact_blank
    mergee_attrs = @mergee_contact.attributes.slice(*MERGEABLE_KEYS).compact_blank

    merged_attrs = mergee_attrs.deep_merge(base_attrs)

    @mergee_contact.destroy!
    @base_contact.update!(merged_attrs)
  end
end
