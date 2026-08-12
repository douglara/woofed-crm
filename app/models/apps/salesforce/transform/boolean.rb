# frozen_string_literal: true

# Checkbox fields are real booleans over REST and the strings "true"/"false" in
# Bulk CSV.
class Apps::Salesforce::Transform::Boolean
  TRUE_VALUES = ['true', '1', 't', 'yes', true, 1].freeze

  def self.call(value, _options = {})
    return { ok: nil } if value.nil? || value == ''

    { ok: TRUE_VALUES.include?(value.is_a?(String) ? value.downcase : value) }
  end
end
