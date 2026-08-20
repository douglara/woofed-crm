# frozen_string_literal: true

# == Schema Information
#
# Table name: apps_salesforce_sync_runs
#
#  id                 :bigint           not null, primary key
#  cursor             :datetime
#  error              :text
#  finished_at        :datetime
#  kind               :string           default("backfill"), not null
#  locator            :string
#  records_downloaded :bigint           default(0), not null
#  records_failed     :bigint           default(0), not null
#  salesforce_object  :string           not null
#  started_at         :datetime
#  status             :string           default("pending"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  app_id             :bigint           not null
#  bulk_job_id        :string
#
# Indexes
#
#  index_apps_salesforce_sync_runs_on_app_id            (app_id)
#  index_salesforce_sync_runs_on_app_object_and_status  (app_id,salesforce_object,status)
#
# Foreign Keys
#
#  fk_rails_...  (app_id => apps_salesforces.id)
#
# One execution of a backfill or a delta sweep for a single Salesforce object.
#
# It also carries the resumption state: the bulk job id and the download locator
# live here, not in job arguments, so a retry polls the job the org already has
# instead of creating a second one, and a download that dies at 80% continues
# from its checkpoint.
class Apps::Salesforce::SyncRun < ApplicationRecord
  self.table_name = 'apps_salesforce_sync_runs'

  belongs_to :app, class_name: 'Apps::Salesforce'
  has_many :raw_records, class_name: 'Apps::Salesforce::RawRecord', dependent: :nullify

  enum kind: {
    'backfill': 'backfill',
    'delta': 'delta'
  }

  enum status: {
    'pending': 'pending',
    'running': 'running',
    'completed': 'completed',
    'failed': 'failed'
  }

  validates :salesforce_object, presence: true

  scope :unfinished, -> { where(status: %w[pending running]) }

  # Where the next run of this object should start from: the cursor of the last
  # one that actually finished.
  def self.last_cursor(app_id, salesforce_object)
    completed.where(app_id: app_id, salesforce_object: salesforce_object).maximum(:cursor)
  end

  # The cursor is stamped at submission, not at the end and not from the newest
  # record downloaded. A download can run for an hour, and a record edited while
  # it runs was already fetched with its old values -- its new modification stamp
  # can still be older than the newest row of the run, so a cursor taken from the
  # data would skip it forever. Starting the next run slightly in the past only
  # costs re-reading a few records, which the load ignores as unchanged.
  def start!
    update!(status: 'running', started_at: Time.current, cursor: Time.current)
  end

  # Only a finished run advances the cursor: completing a partial one would
  # silently skip everything it did not get to.
  def complete!
    update!(status: 'completed', finished_at: Time.current)
  end

  def fail!(message)
    update!(status: 'failed', finished_at: Time.current, error: message)
  end
end
