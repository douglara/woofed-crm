# frozen_string_literal: true

# Decides whether a staged row updates a Woofed record or creates one.
#
#   record link exists?      → that record, update it
#   email or phone matches?  → adopt that record, and link it from now on
#   neither                  → a new record
#
# The middle case is what keeps the first sync from duplicating half the CRM:
# someone the sales team added by hand last week is the same person Salesforce is
# now sending, and `contacts` has a unique index on lower(email), so creating a
# second one would fail on insert anyway.
#
# Email is matched before phone -- an email identifies a person far more reliably
# than a number that may be the company switchboard.
class Apps::Salesforce::Load::Record::FindOrBuild
  MATCHABLE_FIELDS = %w[email phone].freeze

  def initialize(raw_record, object_mapping, attributes)
    @raw_record = raw_record
    @object_mapping = object_mapping
    @attributes = attributes
  end

  def call
    link = existing_link
    return { ok: link.recordable, link: link } if link.present?

    { ok: matched_record || model.new, link: nil }
  end

  private

  attr_reader :raw_record, :object_mapping, :attributes

  def existing_link
    Apps::Salesforce::RecordLink.find_by(
      app_id: raw_record.app_id,
      salesforce_object: raw_record.salesforce_object,
      salesforce_id: raw_record.salesforce_id
    )
  end

  def matched_record
    MATCHABLE_FIELDS.filter_map { |field| match_on(field) }.first
  end

  def match_on(field)
    value = attributes[field]
    return nil if value.blank? || !model.column_names.include?(field)

    field == 'email' ? model.find_by(field => value.to_s.downcase) : model.find_by(field => value)
  end

  def model
    @model ||= Apps::Salesforce::WoofedFields::MODELS.dig(object_mapping.woofed_model, :model)
  end
end
