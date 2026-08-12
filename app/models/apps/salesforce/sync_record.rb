# frozen_string_literal: true

# == Schema Information
#
# Table name: apps_salesforce_sync_records
#
#  id                :bigint           not null, primary key
#  error             :text
#  payload           :jsonb            not null
#  processed_at      :datetime
#  salesforce_object :string           not null
#  status            :string           default("pending"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  app_id            :bigint           not null
#  salesforce_id     :string           not null
#  sync_run_id       :bigint
#
# Indexes
#
#  index_apps_salesforce_sync_records_on_app_id        (app_id)
#  index_apps_salesforce_sync_records_on_sync_run_id   (sync_run_id)
#  index_salesforce_sync_records_on_app_and_status     (app_id,status)
#  index_salesforce_sync_records_on_app_object_and_id  (app_id,salesforce_object,salesforce_id)
#
# Foreign Keys
#
#  fk_rails_...  (app_id => apps_salesforces.id)
#  fk_rails_...  (sync_run_id => apps_salesforce_sync_runs.id)
#
# A raw row as Salesforce sent it, staged before any mapping is applied.
#
# Keeping the payload means a changed field mapping is re-run locally instead of
# downloading the org again, and it gives rows that could not be imported a place
# to live: a contact whose email already belongs to another Woofed record becomes
# a conflict here, with its reason, instead of silently disappearing.
class Apps::Salesforce::SyncRecord < ApplicationRecord
  self.table_name = 'apps_salesforce_sync_records'

  belongs_to :app, class_name: 'Apps::Salesforce'
  belongs_to :sync_run, class_name: 'Apps::Salesforce::SyncRun', optional: true

  enum status: {
    'pending': 'pending',
    'processed': 'processed',
    'failed': 'failed',
    'conflict': 'conflict'
  }

  normalizes :salesforce_id, with: ->(value) { Apps::Salesforce::RecordId.call(value) }

  validates :salesforce_object, presence: true
  validates :salesforce_id, presence: true

  def mark_processed!
    update!(status: 'processed', processed_at: Time.current, error: nil)
  end

  def mark_failed!(message)
    update!(status: 'failed', processed_at: Time.current, error: message)
  end

  # Not a failure to retry: a human has to decide which record wins.
  def mark_conflict!(message)
    update!(status: 'conflict', processed_at: Time.current, error: message)
  end
end
