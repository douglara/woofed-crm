# == Schema Information
#
# Table name: events
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  app_type              :string
#  custom_attributes     :jsonb
#  done                  :boolean
#  done_at               :datetime
#  due                   :datetime
#  from_me               :boolean
#  kind                  :string           default("note"), not null
#  status                :integer
#  title                 :string           default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#  app_id                :bigint
#  contact_id            :bigint
#  deal_id               :bigint
#
# Indexes
#
#  index_events_on_account_id  (account_id)
#  index_events_on_app         (app_type,app_id)
#  index_events_on_contact_id  (contact_id)
#  index_events_on_deal_id     (deal_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Event < ApplicationRecord
  # default_scope { order('created_at DESC') }

  belongs_to :deal, optional: true
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
    'wpp_connect_message': 'wpp_connect_message',
    'wpp_connect_information': 'wpp_connect_information',
    'activity': 'activity',
    'chatwoot_message': 'chatwoot_message',
  }

  def icon_key
    if kind == 'note'
      return 'far fa-sticky-note'
    elsif kind == 'wpp_connect_message'
      return 'fab fa-whatsapp'
    elsif kind == 'activity'
      return 'far fa-calendar'
    elsif kind == 'chatwoot_message'
      return 'far fa-comments'
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
