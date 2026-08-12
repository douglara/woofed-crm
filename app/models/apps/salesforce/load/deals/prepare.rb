# frozen_string_literal: true

# Fills in what a Woofed deal needs and a Salesforce opportunity does not carry:
# a stage, the pipeline that stage belongs to, a contact, and an outcome.
#
# A row that cannot get a stage or a contact is reported instead of guessed. Both
# are required columns, so the alternative is an insert that fails with a
# database error nobody can act on.
class Apps::Salesforce::Load::Deals::Prepare
  def self.call(deal, sync_record, object_mapping)
    new(deal, sync_record, object_mapping).call
  end

  def initialize(deal, sync_record, object_mapping)
    @deal = deal
    @sync_record = sync_record
    @object_mapping = object_mapping
  end

  def call
    stage = Apps::Salesforce::Load::Deals::FindStage.call(object_mapping, payload['StageName'])
    return { skip: I18n.t('apps.salesforce.load.stage_not_mapped', stage: payload['StageName']) } if stage.blank?

    contact = deal.contact || Apps::Salesforce::Load::Deals::FindContact.call(sync_record, object_mapping)
    return { skip: I18n.t('apps.salesforce.load.contact_not_found') } if contact.blank?

    assign(stage, contact)

    { ok: deal }
  end

  private

  attr_reader :deal, :sync_record, :object_mapping

  def assign(stage, contact)
    deal.stage = stage
    deal.pipeline = stage.pipeline
    deal.contact = contact
    apply_outcome
    link_company
  end

  # IsWon and IsClosed together say where the opportunity ended up; the closing
  # date is what Woofed shows as when it happened.
  def apply_outcome
    return deal.status = 'open' unless truthy?(payload['IsClosed'])

    if truthy?(payload['IsWon'])
      deal.status = 'won'
      deal.won_at = closed_at
    else
      deal.status = 'lost'
      deal.lost_at = closed_at
    end
  end

  # The opportunity's Account, already imported, is the company the deal belongs
  # to. Assigned rather than appended so re-running does not pile up duplicates.
  def link_company
    company = Apps::Salesforce::Load::FindMapped.call(
      sync_record, salesforce_field: 'AccountId', recordable_type: 'Company'
    )
    return if company.blank? || deal.companies.include?(company)

    deal.companies = deal.companies.to_a + [company]
  end

  def closed_at
    Apps::Salesforce::Transform::Datetime.call(payload['CloseDate'])[:ok] || Time.current
  end

  def truthy?(value)
    Apps::Salesforce::Transform::Boolean.call(value)[:ok] == true
  end

  def payload
    sync_record.payload
  end
end
