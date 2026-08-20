# frozen_string_literal: true

# Writes a downloaded page of raw rows into staging and advances the run's
# counter.
#
# Rows go in through `insert_all`: a bulk page carries ten thousand records, far
# more than Woofed can validate and save one at a time, and nothing here needs
# callbacks -- these are raw payloads, not Woofed records yet. Turning them into
# contacts and companies is the load step's work.
#
# The run's cursor is deliberately not touched here. It is set to the instant the
# query was submitted, because a record edited *during* a long download would
# otherwise be missed: it was already downloaded with its old values, and its new
# modification stamp can still be older than the newest row of the run.
class Apps::Salesforce::Backfill::StoreRecords
  def initialize(sync_run, records)
    @sync_run = sync_run
    @records = records
  end

  def call
    return { ok: 0 } if rows.blank?

    Apps::Salesforce::RawRecord.insert_all(rows)
    sync_run.update!(records_downloaded: sync_run.records_downloaded + rows.size)

    { ok: rows.size }
  end

  private

  attr_reader :sync_run, :records

  def rows
    @rows ||= Array(records).filter_map do |record|
      salesforce_id = Apps::Salesforce::RecordId.call(record['Id'])
      next if salesforce_id.blank?

      staged_row(record, salesforce_id)
    end
  end

  def staged_row(record, salesforce_id)
    {
      app_id: sync_run.app_id,
      sync_run_id: sync_run.id,
      salesforce_object: sync_run.salesforce_object,
      salesforce_id: salesforce_id,
      payload: record,
      status: 'pending',
      created_at: Time.current,
      updated_at: Time.current
    }
  end
end
