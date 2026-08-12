# frozen_string_literal: true

# The identity map: which Salesforce record is which Woofed record.
#
# It is what makes re-running a sync idempotent -- the loader finds the mapping
# and updates instead of inserting -- what lets an unchanged record be skipped,
# and what keeps a Woofed record alive after the Salesforce one is deleted.
class Apps::Salesforce::RecordMapping < ApplicationRecord
  self.table_name = 'apps_salesforce_record_mappings'

  belongs_to :app, class_name: 'Apps::Salesforce'
  belongs_to :recordable, polymorphic: true

  enum sync_status: {
    'pending': 'pending',
    'synced': 'synced',
    'failed': 'failed'
  }

  normalizes :salesforce_id, with: ->(value) { Apps::Salesforce::RecordId.call(value) }

  validates :salesforce_object, presence: true
  validates :salesforce_id, presence: true, uniqueness: { scope: %i[app_id salesforce_object] }

  scope :active, -> { where(deleted_at: nil) }

  # Salesforce sends every record on every sweep, changed or not. Comparing the
  # remote modification stamp is what keeps a delta run from rewriting rows that
  # are already up to date.
  def outdated?(system_modstamp)
    return true if salesforce_system_modstamp.blank? || system_modstamp.blank?

    system_modstamp.to_time > salesforce_system_modstamp
  end

  # The Salesforce record is gone; the Woofed one stays, along with whatever the
  # user built on top of it.
  def tombstone!
    update!(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end
end
