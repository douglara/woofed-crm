# frozen_string_literal: true

# The Woofed record a Salesforce lookup points at.
#
# Salesforce objects reference each other by id -- an Opportunity's `AccountId`,
# a Task's `WhoId` and `WhatId` -- and every one of those ids was already
# imported and linked. This reads the record links in that direction.
#
# The lookup is by recordable type rather than by Salesforce object name, because
# a Company may have been mapped from Account in one org and from Empresa__c in
# another, and `WhatId` can point at several kinds of object at once.
class Apps::Salesforce::Load::FindLinked
  def self.call(raw_record, salesforce_field:, recordable_type:)
    salesforce_id = Apps::Salesforce::RecordId.call(raw_record.payload[salesforce_field])
    return nil if salesforce_id.blank?

    Apps::Salesforce::RecordLink.find_by(
      app_id: raw_record.app_id, salesforce_id: salesforce_id, recordable_type: recordable_type
    )&.recordable
  end
end
