class Event < ApplicationRecord
  default_scope { order('created_at DESC') }

  belongs_to :deal
  belongs_to :contact
  belongs_to :account
  belongs_to :event_kind
  # belongs_to :record, polymorphic: true
  has_rich_text :content

  after_create_commit {
    broadcast_prepend_to [contact_id, 'events'],
    partial: "accounts/contacts/events/event"
  }

  after_update_commit {
    broadcast_replace_to [contact_id, 'events'],
    partial: "accounts/contacts/events/event"
  }

  scope :planned, -> {
    where(done: false)
  }

  def due_format
    due.to_s(:short) rescue ''
  end

  def overdue?
    return false if self.done == true || due.blank?
    DateTime.now < due
  end
end
