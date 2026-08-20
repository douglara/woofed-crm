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
    result = Apps::Salesforce::Api::Sobject::Describe.call(object_mapping.app, object_mapping.salesforce_object)

    # A describe the org refused must not stop the sync: the query still works
    # with the mapped fields, it just cannot resolve relationships.
    return semantic_fields(object_mapping) if result.key?(:error)

    (reference_fields(result[:ok]) + semantic_fields(object_mapping)).uniq
  end

  def self.reference_fields(payload)
    payload.fetch('fields', [])
           .select { |field| field['type'] == 'reference' && field['name'].present? }
           .map { |field| field['name'] }
  end

  def self.semantic_fields(object_mapping)
    SEMANTIC_FIELDS.fetch(object_mapping.salesforce_object, []) + configured_fields(object_mapping)
  end

  # The fields a Deal mapping names for itself, which are in neither list above:
  # a stage is usually a picklist and a contact may be an email column, so the
  # describe does not report them as references, and neither maps to a Woofed
  # column of its own, so nothing puts them among the mapped fields either.
  # Selecting them here is what puts them in the stored payload -- a field the
  # query never asked for is one the loader cannot read back, however well the
  # mapping is configured.
  #
  # The company is absent on purpose: it can only be a lookup, so it is already
  # among the references.
  #
  # The stage is read raw rather than through `object_mapping.stage_field`,
  # because that falls back to `StageName` -- and asking a custom object for a
  # field it does not have makes Salesforce reject the whole query.
  def self.configured_fields(object_mapping)
    return [] unless object_mapping.woofed_model == 'Deal'

    [object_mapping.options['stage_field'].presence, object_mapping.contact_field].compact
  end

  private_class_method :reference_fields, :semantic_fields, :configured_fields
end
