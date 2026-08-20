# frozen_string_literal: true

# Which field of the Salesforce object plays each part a Woofed deal needs: the
# stage it sits on, the company it belongs to, the person it hangs on.
#
# A standard Opportunity has a name for all of them, and the loader used to
# assume those names. A custom object mapped onto Deal names its own -- one org
# calls the company `School__c`, another `Empresa__c` -- so every such row failed
# against fields it never had. The mapping states the correspondence instead.
#
# Only Deal reads any of this. Company, Contact and Event are saved from their
# mapped fields alone.
module Apps::Salesforce::ObjectMapping::DealFields
  extend ActiveSupport::Concern

  DEFAULT_STAGE_FIELD = 'StageName'
  DEFAULT_COMPANY_FIELD = 'AccountId'

  def stage_field
    options['stage_field'].presence || DEFAULT_STAGE_FIELD
  end

  def company_field
    options['company_field'].presence || DEFAULT_COMPANY_FIELD
  end

  # No standard name to fall back on: an Opportunity relates to people through
  # OpportunityContactRole rather than a lookup, so an org that has a contact
  # lookup at all is one that built it, and only the user can name it. Without
  # one the contact is still looked for through the company.
  def contact_field
    options['contact_field'].presence
  end
end
