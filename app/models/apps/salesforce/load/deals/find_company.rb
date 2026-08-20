# frozen_string_literal: true

# The Woofed company a Salesforce record belongs to, read through the lookup the
# mapping named.
#
# The lookup holds a Salesforce id, so the answer comes from the identity map:
# the company must already have been imported, which is why the object it comes
# from has to be synced before the deals. A lookup pointing at a record Woofed
# never saw resolves to nothing, and the deal is simply not linked.
#
# Both the deal's company link and its contact go through here -- an Opportunity
# names it `AccountId`, a custom object names its own, and neither caller should
# have to know which.
class Apps::Salesforce::Load::Deals::FindCompany
  def self.call(raw_record, object_mapping)
    Apps::Salesforce::Load::FindLinked.call(
      raw_record, salesforce_field: object_mapping.company_field, recordable_type: 'Company'
    )
  end
end
