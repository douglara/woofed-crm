# frozen_string_literal: true

# Runs SOQL and follows the pagination to the end.
#
# Salesforce answers with at most ~2000 records plus a nextRecordsUrl for the
# rest, so every caller would otherwise reimplement the same loop. Pass a block to
# handle each page as it arrives: accumulating a whole object in memory is not an
# option on an org with 100k contacts.
module Apps::Salesforce::ApiClient::Query
  def query(soql, include_deleted: false, &block)
    result = get_request(query_path(include_deleted), q: soql)
    records = []

    loop do
      return result if result.key?(:error)

      page = result[:ok]
      block ? block.call(page['records']) : records.concat(page['records'])

      break if page['done'] || page['nextRecordsUrl'].blank?

      result = get_request(page['nextRecordsUrl'])
    end

    { ok: records }
  end

  private

  # queryAll also returns deleted and archived rows. It is the only way to notice
  # a record that was deleted in Salesforce: a plain query just stops returning it.
  def query_path(include_deleted)
    "#{salesforce.api_url}/#{include_deleted ? 'queryAll' : 'query'}"
  end
end
