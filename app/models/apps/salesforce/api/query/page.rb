# frozen_string_literal: true

# The first page of a SOQL result: at most ~2000 records, plus a nextRecordsUrl
# when there are more.
#
# queryAll also returns deleted and archived rows. It is the only way to notice a
# record that was deleted in Salesforce: a plain query just stops returning it.
class Apps::Salesforce::Api::Query::Page
  def self.call(salesforce, soql, include_deleted: false)
    path = "#{salesforce.api_url}/#{include_deleted ? 'queryAll' : 'query'}"

    salesforce.api_client.get(path, q: soql)
  end
end
