# frozen_string_literal: true

# Submits a Bulk API 2.0 query job and returns its id.
#
# A plain SOQL query costs one API call per page of 2000 records, against an
# allocation of ~100k calls a day that the customer shares with every other
# integration they run. A bulk job costs a handful of calls regardless of volume,
# and its records come out of a separate allocation.
#
# The response carries no records: Salesforce has only accepted the work. The id
# has to be stored, because the only way to learn that the job finished is to ask
# for its state.
class Apps::Salesforce::Api::Bulk::Query::Create
  def self.call(salesforce, soql, include_deleted: false)
    result = salesforce.api_client.post(
      salesforce.bulk_query_url,
      operation: include_deleted ? 'queryAll' : 'query',
      query: soql
    )
    return result if result.key?(:error)

    { ok: result[:ok]['id'] }
  end
end
