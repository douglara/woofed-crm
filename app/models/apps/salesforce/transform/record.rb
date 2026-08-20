# frozen_string_literal: true

# Turns one raw Salesforce row into the attributes a Woofed record is built
# from, driven entirely by the user's field mapping.
#
# It never touches the database: the result is a plain hash, so the same staged
# payload can be re-transformed after a mapping change without downloading the
# org again.
#
# A value that cannot be converted does not fail the row. It is reported as a
# warning and the original is kept under `additional_attributes`, because a
# contact with an unusable phone number is still worth importing -- dropping the
# record loses far more than the field does.
class Apps::Salesforce::Transform::Record
  def initialize(object_mapping, payload)
    @object_mapping = object_mapping
    @payload = payload
  end

  def call
    result = { attributes: {}, custom_attributes: {}, additional_attributes: base_additional_attributes }
    warnings = []

    object_mapping.field_mappings.each do |field_mapping|
      apply(field_mapping, result, warnings)
    end

    { ok: result, warnings: warnings }
  end

  private

  attr_reader :object_mapping, :payload

  def apply(field_mapping, result, warnings)
    salesforce_field = field_mapping['salesforce_field']
    woofed_field = field_mapping['woofed_field']
    return if salesforce_field.blank? || woofed_field.blank?

    # A field Salesforce did not send carries no information about the record, so
    # it is left alone. A field it sent empty is a value the user cleared, and
    # does get written. CDC events only carry changed fields, so conflating the
    # two would let a phone update wipe the rest of the contact.
    return unless payload.key?(salesforce_field)

    converted = Apps::Salesforce::Transform::Value.call(
      transform_name(field_mapping), payload[salesforce_field], transform_options
    )

    return keep_raw(field_mapping, converted, result, warnings) if converted.key?(:error)

    store(field_mapping, converted[:ok], result)
  end

  def store(field_mapping, value, result)
    if field_mapping['kind'].to_s == 'custom_attribute'
      result[:custom_attributes][field_mapping['woofed_field']] = value
    else
      result[:attributes][field_mapping['woofed_field']] = value
    end
  end

  # The original stays visible on the record, so a user can see what Salesforce
  # actually had and fix it there.
  def keep_raw(field_mapping, converted, result, warnings)
    result[:additional_attributes]["salesforce_#{field_mapping['woofed_field']}_raw"] = converted[:raw]
    warnings << converted[:error]
  end

  def transform_name(field_mapping)
    field_mapping['transform'].presence || Apps::Salesforce::Transform::Inferred.call(
      object_mapping.woofed_model, field_mapping['woofed_field'], kind: field_mapping['kind']
    )
  end

  def transform_options
    object_mapping.options.slice('country_code')
  end

  # Mirrors the Salesforce id onto the record so it stays visible in the detail
  # screen and searchable, the way chatwoot_id already is. The mapping table
  # remains the source of truth.
  def base_additional_attributes
    { 'salesforce_id' => Apps::Salesforce::RecordId.call(payload['Id']) }
  end
end
