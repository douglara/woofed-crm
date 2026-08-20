# frozen_string_literal: true

# Multi-select picklists arrive semicolon-delimited in a single field
# ("Varejo;Saúde"), which is meaningless to Woofed until it is split.
class Apps::Salesforce::Transform::PicklistToLabelList
  def self.call(value, _options = {})
    return { ok: [] } if value.blank?

    { ok: value.to_s.split(';').map(&:strip).reject(&:blank?) }
  end
end
