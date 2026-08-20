# frozen_string_literal: true

# Salesforce sends ISO 8601 ("2026-08-01T14:22:31.000+0000" over REST, "…Z" in
# Bulk CSV) and plain dates for date fields.
#
# Everything is parsed and stored as UTC, including values that carry no offset:
# the browser renders each timestamp in the viewer's timezone, so the stored
# instant has to be zone-independent. Parsing in the app's zone would shift a
# date field by the server's offset.
class Apps::Salesforce::Transform::Datetime
  def self.call(value, _options = {})
    return { ok: nil } if value.blank?

    parsed = Time.find_zone('UTC').parse(value.to_s)
    return { error: invalid(value), raw: value } if parsed.blank?

    { ok: parsed }
  rescue ArgumentError
    { error: invalid(value), raw: value }
  end

  def self.invalid(value)
    I18n.t('apps.salesforce.transforms.invalid_datetime', value: value)
  end

  private_class_method :invalid
end
