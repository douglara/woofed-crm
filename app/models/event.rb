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
#  kind                  :string           not null
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
  include Deal::Broadcastable
  # default_scope { order('created_at DESC') }

  belongs_to :deal, optional: true
  belongs_to :contact
  belongs_to :account
  # belongs_to :event_kind, default: -> { EventKind }
  # belongs_to :record, polymorphic: true
  belongs_to :app, polymorphic: true, optional: true
  has_rich_text :content

  attribute :done, :boolean
  attribute :send_now, :boolean
  validates :kind, presence: true

  after_commit do
    # To refactory
    if send_now == true
      Accounts::Contacts::Events::SendNow.call(self)
    elsif scheduled_delivery_event?
      Accounts::Contacts::Events::EnqueueWorker.perform_async(id)
    end
  end

  def changed_scheduled_values?
    saved_change_to_scheduled_at? || saved_change_to_auto_done?
  end

  def scheduled_delivery_event?
    changed_scheduled_values? && (auto_done == true && scheduled_at.present? && done_at.blank?)
  end

  def done
    done_at.present?
  end

  def done?
    done
  end

  def done=(value)
    value_boolean = ActiveRecord::Type::Boolean.new.cast(value)
    return if value_boolean == done

    self.done_at = (Time.now if value_boolean == true)
  end

  def send_now=(value)
    self[:send_now] = ActiveRecord::Type::Boolean.new.cast(value)
  end

  scope :to_do, lambda {
    where('done_at IS NULL').order(:scheduled_at)
  }

  scope :planned, lambda {
    to_do.where('auto_done = false AND scheduled_at IS NOT NULL').order(:scheduled_at)
  }

  scope :scheduled, lambda {
    to_do.where('auto_done = true AND scheduled_at IS NOT NULL')
  }

  scope :planned_overdue, lambda  {
    planned.where('scheduled_at < ?', DateTime.current)
  }

  scope :planned_without_date, lambda  {
    to_do.where('auto_done = false AND scheduled_at IS NULL')
  }

  scope :done, lambda {
    where('done_at IS NOT NULL').order(done_at: :desc)
  }

  enum kind: {
    'note': 'note',
    'evolution_api_message': 'evolution_api_message',
    'activity': 'activity',
    'chatwoot_message': 'chatwoot_message'
  }

  before_validation do
    self.done = false if scheduled_at.present? && done.nil?
  end

  def icon_key
    if kind == 'note'
      'menu-square'
    elsif kind == 'evolution_api_message'
      'fab fa-whatsapp'
    elsif kind == 'activity'
      'clipboard-list'
    elsif kind == 'chatwoot_message'
      'message-circle'
    end
  end

  def editable?
    return true if %w[note activity].include?(kind)
    return true if %w[chatwoot_message evolution_api_message].include?(kind) && !done?

    false
  end

  def overdue?
    return false if done == true || scheduled_at.blank?

    DateTime.current > scheduled_at
  end

  def primary_date
    if scheduled_at.present?
      scheduled_at_format
    else
      created_at.to_s(:short)
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
    if done == true
      'done'
    else
      'scheduled'
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
