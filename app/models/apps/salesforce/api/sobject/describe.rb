# frozen_string_literal: true

# Field metadata for a Salesforce object: every field with its api name, label,
# type and picklist values.
#
# It cannot be hardcoded because every org has its own custom fields, so the
# mapping screen asks the org what it has before offering anything to map.
class Apps::Salesforce::Api::Sobject::Describe
  # The payload is large and only changes when an admin edits the object, so it is
  # cached. Failures are never cached.
  CACHE_TTL = 12.hours

  def self.call(salesforce, object_name)
    Rails.cache.fetch(cache_key(salesforce, object_name), expires_in: CACHE_TTL) do
      result = salesforce.api_client.get("#{salesforce.api_url}/sobjects/#{object_name}/describe")
      return result if result.key?(:error)

      { ok: result[:ok] }
    end
  end

  # The api version is part of the key: bumping it changes the payload shape.
  def self.cache_key(salesforce, object_name)
    "apps_salesforce/#{salesforce.id}/#{salesforce.api_version}/describe/#{object_name}"
  end

  private_class_method :cache_key
end
