# frozen_string_literal: true

# Asks whether the bulk job finished, and reschedules itself until it has.
#
# Salesforce never announces the end of a job, so the only way to know is to ask,
# and a job over a large object can run for more than an hour. Every poll is an
# API call spent against the customer's allocation, so the interval grows instead
# of hammering a fixed five seconds for an hour.
class Apps::Salesforce::Backfill::PollJob < ApplicationJob
  self.queue_adapter = :good_job

  BACKOFF = [10.seconds, 30.seconds, 1.minute, 2.minutes, 5.minutes].freeze
  # A job that has not finished after this many polls is treated as stuck, rather
  # than polled forever.
  MAX_ATTEMPTS = 200
  FINISHED_STATES = %w[JobComplete Failed Aborted].freeze

  def perform(sync_run_id, attempt = 0)
    @sync_run = Apps::Salesforce::SyncRun.find_by(id: sync_run_id)
    return if sync_run.blank? || sync_run.bulk_job_id.blank? || FINISHED_STATES.include?(sync_run.status)

    result = Apps::Salesforce::Api::Bulk::Query::State.call(sync_run.app, sync_run.bulk_job_id)
    return sync_run.fail!(result[:error]) if result.key?(:error)

    handle(result[:ok], attempt)
  end

  private

  attr_reader :sync_run

  def handle(state, attempt)
    case state
    when 'JobComplete' then Apps::Salesforce::Backfill::DownloadJob.perform_later(sync_run.id)
    when 'Failed', 'Aborted' then sync_run.fail!(I18n.t('apps.salesforce.backfill.bulk_job_failed', state: state))
    else poll_again(attempt)
    end
  end

  def poll_again(attempt)
    return sync_run.fail!(I18n.t('apps.salesforce.backfill.bulk_job_stuck')) if attempt >= MAX_ATTEMPTS

    self.class.set(wait: BACKOFF[[attempt, BACKOFF.size - 1].min]).perform_later(sync_run.id, attempt + 1)
  end
end
