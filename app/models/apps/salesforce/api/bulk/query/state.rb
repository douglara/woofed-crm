# frozen_string_literal: true

# Asks where a bulk job is: UploadComplete, InProgress, JobComplete, Failed or
# Aborted.
#
# Salesforce never announces that a job finished and a job can run for over an
# hour, so this is polled by a job that reschedules itself with backoff -- every
# poll is a call spent against the customer's allocation.
class Apps::Salesforce::Api::Bulk::Query::State
  def self.call(salesforce, job_id)
    result = salesforce.api_client.get("#{salesforce.bulk_query_url}/#{job_id}")
    return result if result.key?(:error)

    { ok: result[:ok]['state'] }
  end
end
