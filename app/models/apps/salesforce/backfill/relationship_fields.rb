# frozen_string_literal: true

# The fields a query has to carry beyond the ones the user mapped, so the loader
# can resolve what a record points at.
#
# Reference fields are read from the object's describe rather than from a fixed
# list, because a custom object has its own lookups and nobody can enumerate them
# in advance. Asking for a field the object does not have makes Salesforce reject
# the whole query, so the describe is also what keeps the query valid.
class Apps::Salesforce::Backfill::RelationshipFields
  # Fields the loader needs for a specific meaning rather than for a link: an
  # Opportunity's stage and outcome, a converted Lead's destination. They only
  # exist on standard objects, and a custom object has no equivalent semantics.
  SEMANTIC_FIELDS = {
    'Opportunity' => %w[StageName IsWon IsClosed CloseDate],
    'Lead' => %w[IsConverted]
  }.freeze

  def self.call(object_mapping)
    salesforce_object = object_mapping.salesforce_object
    result = Apps::Salesforce::Api::Sobject::Describe.call(object_mapping.app, salesforce_object)

    # A describe the org refused must not stop the sync: the query still works
    # with the mapped fields, it just cannot resolve relationships.
    return semantic_fields(salesforce_object) if result.key?(:error)

    (reference_fields(result[:ok]) + semantic_fields(salesforce_object)).uniq
  end

  def self.reference_fields(payload)
    payload.fetch('fields', [])
           .select { |field| field['type'] == 'reference' && field['name'].present? }
           .map { |field| field['name'] }
  end

  def self.semantic_fields(salesforce_object)
    SEMANTIC_FIELDS.fetch(salesforce_object, [])
  end

  private_class_method :reference_fields, :semantic_fields
end
