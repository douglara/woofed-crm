# frozen_string_literal: true

# Loads a chunk of staged rows.
#
# Downloading and loading are deliberately separate: bulk pages arrive far faster
# than Woofed can validate and save records, and a row that fails to load must not
# take the download down with it. Each row is loaded on its own, so one bad record
# costs one row rather than the batch.
class Apps::Salesforce::Load::BatchWorker
  include Sidekiq::Worker

  BATCH_SIZE = 500

  def perform(sync_run_id)
    sync_run = Apps::Salesforce::SyncRun.find_by(id: sync_run_id)
    return if sync_run.blank?

    sync_run.sync_records.pending.find_each(batch_size: BATCH_SIZE) do |sync_record|
      Apps::Salesforce::Load::Record.new(sync_record).call
    end

    count_failures(sync_run)
  end

  private

  # What the sync screen reports as "rows that did not make it", conflicts
  # included: they are not errors to retry, they are decisions waiting.
  def count_failures(sync_run)
    sync_run.update!(records_failed: sync_run.sync_records.where(status: %w[failed conflict]).count)
  end
end
