# frozen_string_literal: true

# Which contact a Salesforce opportunity hangs on.
#
# Woofed requires a contact on every deal -- `deals.contact_id` is NOT NULL --
# while Salesforce relates an opportunity to an Account and only optionally to
# people, through OpportunityContactRole. So a real case exists that Woofed
# cannot represent: a large opportunity with a company and no person on it.
#
# Two answers are tried, in order:
#
#   1. a contact of the company the opportunity belongs to
#   2. a placeholder contact named after that company -- **only** when the user
#      ticked `create_placeholder_contact` on the mapping
#
# The placeholder is a fiction: a "person" called Acme Ltda, who has no email and
# no phone, created so the deal can exist at all. It is off by default because it
# pollutes the CRM, and offered because for some customers losing million-real
# opportunities on import is worse than carrying contacts named after companies.
#
# With neither, the row is reported and the deal is not imported.
#
# A better answer exists and is not implemented: OpportunityContactRole is where
# Salesforce actually records the people on a deal. It can be fetched as a SOQL
# subquery, but Bulk API 2.0 rejects subqueries -- so exactly the large objects
# that need Bulk would be left out. Doing it properly means a second pass over
# the junction object, which is its own piece of work.
class Apps::Salesforce::Load::Deals::FindContact
  def self.call(sync_record, object_mapping)
    company = Apps::Salesforce::Load::FindCompany.call(sync_record)
    contact = company&.contacts&.first

    return contact if contact.present?
    return nil unless object_mapping.options['create_placeholder_contact']

    placeholder(company, sync_record)
  end

  def self.placeholder(company, sync_record)
    Contact.create!(full_name: company&.name.presence || sync_record.payload['Name'].to_s)
  end

  private_class_method :placeholder
end
