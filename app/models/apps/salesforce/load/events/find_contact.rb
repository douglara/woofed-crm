# frozen_string_literal: true

# Who a Salesforce task or event belongs to.
#
# Salesforce splits an activity's relations in two: `WhoId` points at a person (a
# Contact or a Lead) and `WhatId` at whatever else it concerns -- an Opportunity,
# an Account, a custom object. Woofed requires a contact on every event, so the
# person is looked for in that order:
#
#   1. WhoId, the person Salesforce itself recorded
#   2. the contact of the deal in WhatId
#   3. a contact of the company in WhatId
#
# A call logged against an opportunity with nobody on it, and against a company
# with no contacts, has no one to belong to and is reported instead of imported.
class Apps::Salesforce::Load::Events::FindContact
  def self.call(raw_record)
    from_who_id(raw_record) || from_deal(raw_record) || from_company(raw_record)
  end

  # WhoId is a Contact or a Lead, and both are imported as Woofed contacts.
  def self.from_who_id(raw_record)
    Apps::Salesforce::Load::FindLinked.call(
      raw_record, salesforce_field: 'WhoId', recordable_type: 'Contact'
    )
  end

  def self.from_deal(raw_record)
    Apps::Salesforce::Load::FindLinked.call(
      raw_record, salesforce_field: 'WhatId', recordable_type: 'Deal'
    )&.contact
  end

  def self.from_company(raw_record)
    Apps::Salesforce::Load::FindLinked.call(
      raw_record, salesforce_field: 'WhatId', recordable_type: 'Company'
    )&.contacts&.first
  end

  private_class_method :from_who_id, :from_deal, :from_company
end
