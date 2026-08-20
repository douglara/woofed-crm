# frozen_string_literal: true

# Which contact a Salesforce record hangs on.
#
# Woofed requires a contact on every deal -- `deals.contact_id` is NOT NULL --
# while Salesforce relates an opportunity to an Account and only optionally to
# people, through OpportunityContactRole. So a real case exists that Woofed
# cannot represent: a large opportunity with a company and no person on it.
#
# Three answers are tried, in order:
#
#   1. the contact field the mapping named -- the direct answer, and the only one
#      that names a specific person
#   2. a contact of the company the record belongs to
#   3. a placeholder contact named after that company -- **only** when the user
#      ticked `create_placeholder_contact` on the mapping
#
# That first field does not have to be a lookup. Plenty of objects identify a
# person by an email or a phone column rather than by a relationship, so the
# value is tried as a Salesforce id first, then as an email, then as a phone --
# the same order `Load::Record::FindOrBuild` uses, and for the same reason: an
# email identifies a person far more reliably than a number that may be the
# company switchboard. Only one of the three can match a given value, so trying
# them in sequence costs nothing and spares the user from telling Woofed which
# kind of field they picked.
#
# The placeholder is a fiction: a "person" called Acme Ltda, who has no email and
# no phone, created so the deal can exist at all. It is off by default because it
# pollutes the CRM, and offered because for some customers losing million-real
# opportunities on import is worse than carrying contacts named after companies.
#
# With none of the three, the row is reported and the deal is not imported.
#
# A better answer exists for standard opportunities and is not implemented:
# OpportunityContactRole is where Salesforce actually records the people on a
# deal. It can be fetched as a SOQL subquery, but Bulk API 2.0 rejects
# subqueries -- so exactly the large objects that need Bulk would be left out.
# Doing it properly means a second pass over the junction object, which is its
# own piece of work.
class Apps::Salesforce::Load::Deals::FindContact
  def self.call(raw_record, object_mapping)
    mapped_contact(raw_record, object_mapping) || contact_of_company(raw_record, object_mapping)
  end

  def self.mapped_contact(raw_record, object_mapping)
    return nil if object_mapping.contact_field.blank?

    value = raw_record.payload[object_mapping.contact_field].to_s.strip
    return nil if value.blank?

    by_identity(raw_record, object_mapping) || by_email(value) || by_phone(value)
  end

  # A lookup, whose value is a Salesforce id the identity map can resolve. It
  # only finds someone Woofed already imported.
  def self.by_identity(raw_record, object_mapping)
    Apps::Salesforce::Load::FindLinked.call(
      raw_record, salesforce_field: object_mapping.contact_field, recordable_type: 'Contact'
    )
  end

  # Compared case-insensitively rather than against a downcased value: nothing
  # normalises `contacts.email` on write, so a contact saved as `Ana@Example.com`
  # would be missed by an exact match.
  def self.by_email(value)
    Contact.where('lower(contacts.email) = ?', value.downcase).first
  end

  def self.by_phone(value)
    Contact.find_by(phone: value)
  end

  def self.contact_of_company(raw_record, object_mapping)
    company = Apps::Salesforce::Load::Deals::FindCompany.call(raw_record, object_mapping)
    contact = company&.contacts&.first

    return contact if contact.present?
    return nil unless object_mapping.options['create_placeholder_contact']

    placeholder(company, raw_record)
  end

  def self.placeholder(company, raw_record)
    Contact.create!(full_name: company&.name.presence || raw_record.payload['Name'].to_s)
  end

  private_class_method :mapped_contact, :by_identity, :by_email, :by_phone,
                       :contact_of_company, :placeholder
end
