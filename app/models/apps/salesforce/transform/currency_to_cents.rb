# frozen_string_literal: true

# Salesforce currency fields are decimals ("1500.50"); Woofed stores cents
# (150050), which is what Deal::HandleInCentsValues expects.
class Apps::Salesforce::Transform::CurrencyToCents
  def self.call(value, _options = {})
    return { ok: nil } if value.blank?

    { ok: (BigDecimal(value.to_s) * 100).round }
  rescue ArgumentError, TypeError
    { error: I18n.t('apps.salesforce.transforms.invalid_currency', value: value), raw: value }
  end
end
