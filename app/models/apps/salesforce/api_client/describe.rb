# frozen_string_literal: true

# Field metadata for a Salesforce object: every field with its api name, label,
# type and picklist values.
#
# It cannot be hardcoded because every org has its own custom fields, so the
# mapping screen asks the org what it has before offering anything to map.
module Apps::Salesforce::ApiClient::Describe
  # The payload is large and only changes when an admin edits the object, so it is
  # cached. Failures are never cached.
  DESCRIBE_CACHE_TTL = 12.hours

  def describe_object(object_name)
    Rails.cache.fetch(describe_cache_key(object_name), expires_in: DESCRIBE_CACHE_TTL) do
      result = get_request("#{salesforce.api_url}/sobjects/#{object_name}/describe")
      return result if result.key?(:error)

      { ok: result[:ok] }
    end
  end

  private

  # The api version is part of the key: bumping it changes the payload shape.
  def describe_cache_key(object_name)
    "apps_salesforce/#{salesforce.id}/#{salesforce.api_version}/describe/#{object_name}"
  end
end
