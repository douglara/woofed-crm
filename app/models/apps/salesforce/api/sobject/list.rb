# frozen_string_literal: true

# Every object in the org, standard and custom, as the mapping screen's object
# picker needs it.
#
# The list cannot be hardcoded: a Woofed Company may come from Account in one
# org and from School__c or Empresa__c in another. Only the org knows what it
# has.
class Apps::Salesforce::Api::Sobject::List
  CACHE_TTL = 12.hours

  def self.call(salesforce)
    Rails.cache.fetch(cache_key(salesforce), expires_in: CACHE_TTL) do
      result = salesforce.api_client.get("#{salesforce.api_url}/sobjects")
      return result if result.key?(:error)

      { ok: syncable(result[:ok]) }
    end
  end

  # Objects that cannot be queried, or that exist for Salesforce's own
  # bookkeeping, would only be noise in the picker.
  def self.syncable(payload)
    payload.fetch('sobjects', [])
           .select { |sobject| sobject['queryable'] && !sobject['deprecatedAndHidden'] }
           .map { |sobject| sobject.slice('name', 'label', 'custom') }
           .sort_by { |sobject| [sobject['custom'] ? 1 : 0, sobject['label'].to_s] }
  end

  def self.cache_key(salesforce)
    "apps_salesforce/#{salesforce.id}/#{salesforce.api_version}/sobjects"
  end

  private_class_method :syncable, :cache_key
end
