# frozen_string_literal: true

require 'csv'

# Bulk API 2.0 query jobs: the initial load path.
#
# A plain SOQL query costs one API call per page of 2000 records, and an org's
# allocation is ~100k calls per day shared with every other integration the
# customer runs. A bulk job costs a handful of calls no matter how many records it
# returns, and its record volume comes out of a separate allocation.
#
# The three steps are separate on purpose. Salesforce never announces that a job
# finished -- the only way to know is to ask -- and a job can take more than an
# hour, so the polling belongs to a job that reschedules itself rather than to a
# thread sleeping here. Results arrive as CSV and are handed over as rows; turning
# them into Woofed records is the transform layer's work.
class Apps::Salesforce::BulkQuery
  # Salesforce caps a single download; the locator points at the next slice.
  MAX_RECORDS_PER_PAGE = 10_000

  def initialize(salesforce, soql, include_deleted: false)
    @salesforce = salesforce
    @soql = soql
    @include_deleted = include_deleted
  end

  def create
    result = client.post_request(jobs_path, operation: operation, query: soql)
    return result if result.key?(:error)

    { ok: result[:ok]['id'] }
  end

  # UploadComplete / InProgress / JobComplete / Failed / Aborted
  def state(job_id)
    result = client.get_request("#{jobs_path}/#{job_id}")
    return result if result.key?(:error)

    { ok: result[:ok]['state'] }
  end

  # `locator` is nil on the first call and carries the checkpoint afterwards, so a
  # download that dies at 80% resumes where it stopped instead of starting over.
  def results(job_id, locator: nil, max_records: MAX_RECORDS_PER_PAGE)
    params = { maxRecords: max_records }
    params[:locator] = locator if locator.present?

    result = client.get_raw_request("#{jobs_path}/#{job_id}/results", params)
    return result if result.key?(:error)

    { ok: page(result) }
  end

  private

  attr_reader :salesforce, :soql, :include_deleted

  def page(result)
    next_locator = result[:request].headers['Sforce-Locator']
    next_locator = nil if next_locator.blank? || next_locator == 'null'

    { records: parse_csv(result[:ok]), locator: next_locator, done: next_locator.nil? }
  end

  # Every value arrives as a string, and a null is indistinguishable from an empty
  # string. Coercion is the transform layer's problem, not this one's.
  def parse_csv(body)
    return [] if body.blank?

    CSV.parse(body, headers: true).map(&:to_h)
  end

  def operation
    include_deleted ? 'queryAll' : 'query'
  end

  def jobs_path
    "#{salesforce.api_url}/jobs/query"
  end

  def client
    @client ||= Apps::Salesforce::ApiClient.new(salesforce)
  end
end
