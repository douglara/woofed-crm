# frozen_string_literal: true

# Downloads one object, choosing how based on how much there is.
#
# Below the bulk threshold a paged REST query is simpler and finishes sooner: a
# bulk job costs a create, several polls and a download round-trip before the
# first record arrives. Above it, paging REST would spend one API call per 2000
# records against an allocation the customer shares with every other integration
# they run.
class Apps::Salesforce::Backfill::ObjectJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  self.queue_adapter = :good_job

  # Two runs of the same connection must never interleave and race on the same
  # mapping rows.
  good_job_control_concurrency_with(
    perform_limit: 1,
    key: -> { "#{self.class.name}-#{arguments.first}" }
  )

  BULK_THRESHOLD = 50_000

  def perform(sync_run_id)
    @sync_run = Apps::Salesforce::SyncRun.find_by(id: sync_run_id)
    return if sync_run.blank? || sync_run.completed? || sync_run.failed?

    sync_run.start!
    object_mapping.present? ? download : sync_run.fail!(I18n.t('apps.salesforce.backfill.mapping_missing'))
  end

  private

  attr_reader :sync_run

  def download
    count = record_count
    return sync_run.fail!(count[:error]) if count.key?(:error)

    count[:ok] >= BULK_THRESHOLD ? start_bulk_job : download_over_rest
  end

  # A single call that decides the strategy, so a small org never pays for a job
  # and a large one never floods the API allocation.
  def record_count
    result = salesforce.api_client.get("#{salesforce.api_url}/query", q: soql.count)
    return result if result.key?(:error)

    { ok: result[:ok]['totalSize'].to_i }
  end

  def download_over_rest
    result = Apps::Salesforce::Api::Query::AllPages.call(salesforce, soql.call) do |records|
      Apps::Salesforce::Backfill::StoreRecords.new(sync_run, records).call
      # Loading trails the download instead of waiting for it: on a large object
      # the first records are usable long before the last page arrives.
      Apps::Salesforce::Load::BatchWorker.perform_async(sync_run.id)
    end

    result.key?(:error) ? sync_run.fail!(result[:error]) : sync_run.complete!
  end

  # The id is stored before anything else happens: a retry then polls the job the
  # org already has instead of submitting a second one.
  def start_bulk_job
    result = Apps::Salesforce::Api::Bulk::Query::Create.call(salesforce, soql.call)
    return sync_run.fail!(result[:error]) if result.key?(:error)

    sync_run.update!(bulk_job_id: result[:ok])
    Apps::Salesforce::Backfill::PollJob.perform_later(sync_run.id)
  end

  def soql
    @soql ||= Apps::Salesforce::Backfill::Soql.new(
      object_mapping,
      cursor: cursor,
      extra_fields: Apps::Salesforce::Backfill::RelationshipFields.call(object_mapping)
    )
  end

  # A backfill asks for everything; a catch-up only for what changed since the
  # last finished run of this object.
  def cursor
    return nil if sync_run.backfill?

    Apps::Salesforce::SyncRun.last_cursor(sync_run.app_id, sync_run.salesforce_object)
  end

  def object_mapping
    @object_mapping ||= salesforce.object_mappings.find_by(salesforce_object: sync_run.salesforce_object)
  end

  def salesforce
    @salesforce ||= sync_run.app
  end
end
