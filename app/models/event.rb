class Event < ApplicationRecord
  # default_scope { order('created_at DESC') }

  belongs_to :deal
  belongs_to :contact
  belongs_to :account
  # belongs_to :event_kind, default: -> { EventKind }
  # belongs_to :record, polymorphic: true
  belongs_to :app, polymorphic: true, optional: true
  has_rich_text :content

  after_create_commit {
    broadcast_append_to [contact_id, 'events'],
    partial: "accounts/contacts/events/event"

    Accounts::Contacts::Events::CreatedWorker.perform_async(self.id)
  }

  after_update_commit {
    broadcast_replace_to [contact_id, 'events'],
    partial: "accounts/contacts/events/event"
  }

  scope :planned, -> {
    where(done: false)
  }

  enum kind: {
    'note': 'note',
    'wpp_connect_message': 'wpp_connect_message'
  }

  def icon_key
    if kind == 'note'
      return 'far fa-sticky-note'
    elsif kind == 'wpp_connect_message'
      return 'fab fa-whatsapp'
    end
  end

  def due_format
    due.to_s(:short) rescue ''
  end

  def overdue?
    return false if self.done == true || due.blank?
    DateTime.current > due
  end
end
