# frozen_string_literal: true

# The Woofed side of the mapping screen's field pickers: the columns a synced
# model can receive, plus the custom attributes this install has defined for it.
#
# Custom fields matter because a Salesforce custom field has no column to land
# in -- `Industria__c` can only become `custom_attributes['industria']`, which
# requires a CustomAttributeDefinition. Event has no custom attributes in this
# CRM, so it offers columns only.
#
# Ids, timestamps and bookkeeping columns are left out: they are not things a
# Salesforce field can feed.
class Apps::Salesforce::WoofedFields
  MODELS = {
    'Company' => { model: Company, custom_attribute_model: 'company_attribute' },
    'Contact' => { model: Contact, custom_attribute_model: 'contact_attribute' },
    'Deal' => { model: Deal, custom_attribute_model: 'deal_attribute' },
    'Event' => { model: Event, custom_attribute_model: nil }
  }.freeze

  EXCLUDED_COLUMNS = %w[
    id created_at updated_at account_id custom_attributes additional_attributes
  ].freeze

  def self.call(woofed_model)
    definition = MODELS[woofed_model]
    return [] if definition.blank?

    attributes(definition[:model]) + custom_attributes(definition[:custom_attribute_model])
  end

  def self.attributes(model)
    model.column_names.reject { |name| EXCLUDED_COLUMNS.include?(name) || name.end_with?('_id') }
         .map { |name| { name: name, label: name.humanize, kind: 'attribute' } }
  end

  def self.custom_attributes(attribute_model)
    return [] if attribute_model.blank?

    CustomAttributeDefinition.with_attribute_model(attribute_model).map do |definition|
      { name: definition.attribute_key, label: definition.attribute_display_name, kind: 'custom_attribute' }
    end
  end

  private_class_method :attributes, :custom_attributes
end
