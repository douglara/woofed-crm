# frozen_string_literal: true

# The Woofed company a Salesforce lookup points at.
#
# Salesforce's Account is the customer organisation, not a login, and several
# objects point at one: an Opportunity through `AccountId`, a Contact through the
# same field. Whichever object it came from, the Account was already imported as
# a Company -- which is why Accounts are backfilled before everything else.
#
# The lookup is by recordable type rather than by Salesforce object name, because
# a Company may have been mapped from Account in one org and from Empresa__c in
# another.
class Apps::Salesforce::Load::FindCompany
  def self.call(sync_record, salesforce_field: 'AccountId')
    salesforce_id = Apps::Salesforce::RecordId.call(sync_record.payload[salesforce_field])
    return nil if salesforce_id.blank?

    Apps::Salesforce::RecordMapping.find_by(
      app_id: sync_record.app_id, salesforce_id: salesforce_id, recordable_type: 'Company'
    )&.recordable
  end
end
