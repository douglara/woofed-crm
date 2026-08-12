# frozen_string_literal: true

# Dispatches a value to the transform named in the field mapping.
#
# Transforms are referenced by name so a mapping stays data, not code, and an
# unknown name is reported instead of silently importing a raw value.
class Apps::Salesforce::Transform::Value
  TRANSFORMS = {
    'text' => Apps::Salesforce::Transform::Text,
    'currency_to_cents' => Apps::Salesforce::Transform::CurrencyToCents,
    'datetime' => Apps::Salesforce::Transform::Datetime,
    'picklist_to_label_list' => Apps::Salesforce::Transform::PicklistToLabelList,
    'boolean' => Apps::Salesforce::Transform::Boolean,
    'phone' => Apps::Salesforce::Transform::Phone
  }.freeze

  def self.call(name, value, options = {})
    transform = TRANSFORMS[name.to_s]
    return { error: I18n.t('apps.salesforce.transforms.unknown', name: name), raw: value } if transform.blank?

    transform.call(value, options)
  end
end
