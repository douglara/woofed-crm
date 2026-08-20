# frozen_string_literal: true

require 'csv'

# Downloads one slice of a finished bulk job.
#
# Results are CSV only -- there is no JSON option for query jobs -- so every value
# arrives as a string and a null is indistinguishable from an empty string.
# Coercion belongs to the transform layer, not here.
#
# `locator` is nil on the first call and carries the checkpoint afterwards, which
# is what makes a download that dies at 80% resume instead of starting over.
class Apps::Salesforce::Api::Bulk::Query::Results
  # Salesforce caps a single download; the locator points at the next slice.
  MAX_RECORDS_PER_PAGE = 10_000

  def self.call(salesforce, job_id, locator: nil, max_records: MAX_RECORDS_PER_PAGE)
    params = { maxRecords: max_records }
    params[:locator] = locator if locator.present?

    result = salesforce.api_client.get_raw("#{salesforce.bulk_query_url}/#{job_id}/results", params)
    return result if result.key?(:error)

    { ok: page(result) }
  end

  def self.page(result)
    next_locator = result[:request].headers['Sforce-Locator']
    next_locator = nil if next_locator.blank? || next_locator == 'null'

    { records: parse_csv(result[:ok]), locator: next_locator, done: next_locator.nil? }
  end

  def self.parse_csv(body)
    return [] if body.blank?

    CSV.parse(body, headers: true).map(&:to_h)
  end

  private_class_method :page, :parse_csv
end
