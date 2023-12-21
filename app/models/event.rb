# == Schema Information
#
# Table name: events
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  app_type              :string
#  auto_done             :boolean          default(FALSE)
#  custom_attributes     :jsonb
#  done_at               :datetime
#  from_me               :boolean
#  kind                  :string           default("note"), not null
#  scheduled_at          :datetime
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
  include Event::Decorators
  # default_scope { order('created_at DESC') }

  belongs_to :deal, optional: true
  belongs_to :contact
  belongs_to :account

  # belongs_to :event_kind, default: -> { EventKind }
  # belongs_to :record, polymorphic: true
  belongs_to :app, polymorphic: true, optional: true
  has_rich_text :content

  after_create_commit {
    if self.done == false
      broadcast_prepend_to [contact_id, 'events'],
      partial: "accounts/contacts/events/event",
      target: "events_planned_#{contact.id}"
    else
      broadcast_prepend_to [contact_id, 'events'],
      partial: "accounts/contacts/events/event",
      target: "events_not_planned_or_done_#{contact.id}"
    end

    Accounts::Contacts::Events::CreatedWorker.perform_async(self.id)
  }

  after_update_commit {
    broadcast_replace_to [contact_id, 'events'],
    partial: "accounts/contacts/events/event"
  }
  after_destroy_commit {
    broadcast_remove_to [contact_id, 'events']
  }

  scope :planned, -> {
    where('done = false').order(:due)

  }

  scope :not_planned_or_done, -> {
    where('done IS NULL or done = true').order(done_at: :desc)
  }

  enum kind: {
    'note': 'note',
    'wpp_connect_message': 'wpp_connect_message',
    'wpp_connect_information': 'wpp_connect_information',
    'activity': 'activity',
    'chatwoot_message': 'chatwoot_message',
  }

  before_validation do
    if self.due.present? && self.done == nil
      self.done = false
    end
  end

  def icon_key
    if kind == 'note'
      return 'menu-square'
    elsif kind == 'wpp_connect_message'
      return 'fab fa-whatsapp'
    elsif kind == 'activity'
      return 'clipboard-list'
    elsif kind == 'chatwoot_message'
      return 'message-circle'
    end
  end

  def editable?
    ['note', 'activity'].include?(kind)
  end

  def overdue?
    return false if self.done == true || due.blank?
    DateTime.current > due
  end

  def primary_date
    if due.present?
      return due_format
    else
      return created_at.to_s(:short)
    end
  end

  def from
    if from_me == true
      'from-me'
    else
      'from-contacts'
    end
  end

  def scheduled_kind
    if self.done == true
      return 'done'
    else
      return 'scheduled'
    end
  end

  ## Events

  include Wisper::Publisher
  after_commit :publish_created, on: :create
  after_commit :publish_updated, on: :update

  private

  def publish_created
    broadcast(:event_created, self)
  end

  def publish_updated
    broadcast(:event_updated, self)
  end
end
