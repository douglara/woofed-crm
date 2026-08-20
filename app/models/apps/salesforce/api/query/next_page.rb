# frozen_string_literal: true

# Follows the continuation of a result set.
#
# `nextRecordsUrl` is an opaque cursor Salesforce returns in the previous page: it
# already carries the query, how many records were served and whether the call was
# query or queryAll, so nothing else is sent with it.
class Apps::Salesforce::Api::Query::NextPage
  def self.call(salesforce, next_records_url)
    salesforce.api_client.get(next_records_url)
  end
end
