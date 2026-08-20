# frozen_string_literal: true

# Walks a SOQL result to the end so no caller reimplements the pagination.
#
# Pass a block to handle each page as it arrives: accumulating a whole object in
# memory is not an option on an org with 100k contacts.
class Apps::Salesforce::Api::Query::AllPages
  def self.call(salesforce, soql, include_deleted: false, &block)
    result = Apps::Salesforce::Api::Query::Page.call(salesforce, soql, include_deleted: include_deleted)
    records = []

    loop do
      return result if result.key?(:error)

      page = result[:ok]
      block ? block.call(page['records']) : records.concat(page['records'])

      break if page['done'] || page['nextRecordsUrl'].blank?

      result = Apps::Salesforce::Api::Query::NextPage.call(salesforce, page['nextRecordsUrl'])
    end

    { ok: records }
  end
end
