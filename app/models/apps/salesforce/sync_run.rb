# frozen_string_literal: true

# One execution of a backfill or a delta sweep for a single Salesforce object.
#
# It also carries the resumption state: the bulk job id and the download locator
# live here, not in job arguments, so a retry polls the job the org already has
# instead of creating a second one, and a download that dies at 80% continues
# from its checkpoint.
class Apps::Salesforce::SyncRun < ApplicationRecord
  self.table_name = 'apps_salesforce_sync_runs'

  belongs_to :app, class_name: 'Apps::Salesforce'
  has_many :sync_records, class_name: 'Apps::Salesforce::SyncRecord', dependent: :nullify

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

  def start!
    update!(status: 'running', started_at: Time.current)
  end

  # The cursor is the high-water mark the next delta starts from, so it is only
  # advanced when the run actually finished.
  def complete!(cursor: nil)
    update!(status: 'completed', finished_at: Time.current, cursor: cursor || self.cursor)
  end

  def fail!(message)
    update!(status: 'failed', finished_at: Time.current, error: message)
  end
end
