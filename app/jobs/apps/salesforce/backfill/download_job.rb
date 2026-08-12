# frozen_string_literal: true

# Downloads a finished bulk job, one page at a time.
#
# Each page is staged and its locator saved before the next one is asked for, so
# a download that dies at 80% resumes from its checkpoint instead of starting
# over -- which on a 500k object is the difference between minutes and another
# hour of the customer's API allocation.
class Apps::Salesforce::Backfill::DownloadJob < ApplicationJob
  self.queue_adapter = :good_job

  def perform(sync_run_id)
    @sync_run = Apps::Salesforce::SyncRun.find_by(id: sync_run_id)
    return if sync_run.blank? || sync_run.bulk_job_id.blank? || sync_run.completed?

    result = Apps::Salesforce::Api::Bulk::Query::Results.call(
      sync_run.app, sync_run.bulk_job_id, locator: sync_run.locator
    )
    return sync_run.fail!(result[:error]) if result.key?(:error)

    store(result[:ok])
  end

  private

  attr_reader :sync_run

  def store(page)
    Apps::Salesforce::Backfill::StoreRecords.new(sync_run, page[:records]).call
    sync_run.update!(locator: page[:locator])
    # Loading trails the download instead of waiting for it: on a large object
    # the first records are usable long before the last page arrives.
    Apps::Salesforce::Load::BatchWorker.perform_async(sync_run.id)

    page[:done] ? sync_run.complete! : self.class.perform_later(sync_run.id)
  end
end
