# frozen_string_literal: true

# The default transform. Bulk results arrive as CSV, where every value is a
# string and a blank cell is indistinguishable from a null, so both become nil
# and the load step decides what an empty column means.
class Apps::Salesforce::Transform::Text
  def self.call(value, _options = {})
    return { ok: nil } if value.blank?

    { ok: value.to_s.strip }
  end
end
