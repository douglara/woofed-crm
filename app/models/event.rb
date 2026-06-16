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
#  app_id                :bigint
#  contact_id            :bigint
#  deal_id               :bigint
#
# Indexes
#
#  index_events_on_app         (app_type,app_id)
#  index_events_on_contact_id  (contact_id)
#  index_events_on_deal_id     (deal_id)
#
class Event < ApplicationRecord
  include Deal::Broadcastable
  # default_scope { order('created_at DESC') }
  DEAL_UPDATE_KINDS = %w[deal_stage_change deal_opened deal_won deal_lost deal_reopened deal_product_added
                         deal_product_removed].freeze
  belongs_to :deal, optional: true
  belongs_to :contact
  # belongs_to :event_kind, default: -> { EventKind }
  # belongs_to :record, polymorphic: true
  belongs_to :app, polymorphic: true, optional: true
  has_rich_text :content
  alias original_content content

  attribute :done, :boolean
  attribute :send_now, :boolean
  validates :kind, presence: true
  has_one :attachment, as: :attachable

  after_commit do
    # To refactory
    if send_now == true
      Accounts::Contacts::Events::SendNow.call(self)
    elsif scheduled_delivery_event?
      Accounts::Contacts::Events::EnqueueWorker.perform_async(id)
    end
    schedule_webpush_notifications
  end

  attribute :files, default: []
  attribute :files_events, default: []
  attribute :invalid_files

  validate :validate_invalid_files
  validate :validate_chatwoot_template, if: :chatwoot_template?
  # Persist the resolved template text as the event content so the sent message is
  # visible in the CRM timeline (the template form hides the free-text field).
  before_save :store_resolved_template_content, if: :chatwoot_template?

  def validate_invalid_files
    errors.add(:files, 'Invalid files') if invalid_files == true
  end

  def save
    ActiveRecord::Base.transaction do
      @result = super
      return @result if @result == false

      if files_events.present?
        files_events.each do |file_event|
          file_event.save!
        end
      end
    end
    @result
  end

  def schedule_webpush_notifications
    return unless scheduled_at.present? && saved_change_to_scheduled_at? && !send_now

    Pwa::SendNotificationsWorker.set(wait_until: scheduled_at).perform_later(id)
  end

  def content=(value)
    original_content.body = value
  end

  def content
    if text_content? && original_content.body.present?
      original_content.body.to_plain_text
    else
      original_content
    end
  end

  def text_content?
    chatwoot_message? || evolution_api_message?
  end

  def generate_content_hash(key, value)
    if content_is_blank?(value)
      { key.to_s => '' }
    else
      { key.to_s => value }
    end
  end

  def content_is_blank?(value)
    value.respond_to?(:body)
  end

  # === WhatsApp template support (Chatwoot) =================================
  # Template inputs live in additional_attributes; the template definition
  # (name/category/language/components) is derived at send time from the synced
  # data on the app's inboxes, never stored on the event.

  def chatwoot_template?
    chatwoot_message? && additional_attributes['chatwoot_template_name'].present?
  end

  def chatwoot_template_definition
    return nil unless chatwoot_template? && app.respond_to?(:inboxes)

    inbox = Array(app.inboxes).find { |i| i['id'].to_s == additional_attributes['chatwoot_inbox_id'].to_s }
    return nil unless inbox

    Array(inbox['message_templates']).find { |t| t['name'] == additional_attributes['chatwoot_template_name'] }
  end

  # The BODY text with {{n}} replaced by the stored values — the required `content`.
  def resolved_template_content
    template = chatwoot_template_definition
    return content if template.nil?

    body = Array(template['components']).find { |c| c['type'] == 'BODY' }
    params = resolved_template_body_params
    body.to_h['text'].to_s.gsub(/\{\{(\d+)\}\}/) { params[Regexp.last_match(1)].to_s }
  end

  # Assembles Chatwoot's `template_params` payload from the stored inputs.
  def chatwoot_template_params
    template = chatwoot_template_definition
    return nil if template.nil?

    {
      'name' => template['name'],
      'category' => template['category'],
      'language' => template['language'],
      'processed_params' => chatwoot_processed_params(template)
    }
  end

  def chatwoot_processed_params(template)
    components = Array(template['components'])
    processed = {}

    body_params = resolved_template_body_params
    processed['body'] = body_params if body_params.present?

    header = components.find { |c| c['type'] == 'HEADER' }
    if chatwoot_media_header?(header) && additional_attributes['template_header_media_url'].present?
      processed['header'] = {
        'media_url' => resolve_merge_tags(additional_attributes['template_header_media_url']),
        'media_type' => header['format'].to_s.downcase
      }
    end

    buttons = chatwoot_processed_buttons(template)
    processed['buttons'] = buttons if buttons.present?

    processed
  end

  # Only buttons that carry a runtime parameter (a URL containing {{n}}) are sent;
  # static QUICK_REPLY / plain URL buttons come from the template itself.
  def chatwoot_dynamic_buttons(template)
    buttons = Array(template['components']).find { |c| c['type'] == 'BUTTONS' }.to_h['buttons']
    Array(buttons).select { |b| b['type'] == 'URL' && b['url'].to_s =~ /\{\{\d+\}\}/ }
  end

  def chatwoot_processed_buttons(template)
    button_params = additional_attributes['template_button_params'] || {}
    chatwoot_dynamic_buttons(template).each_with_index.filter_map do |_button, index|
      value = resolve_merge_tags(button_params[index.to_s])
      { 'type' => 'url', 'parameter' => value } if value.present?
    end
  end

  CONTACT_MERGE_FIELDS = %w[full_name email phone].freeze

  # Body params with {{contact.<field>}} merge tags resolved against this event's
  # contact, so a bulk send personalises every lead. Plain values pass through.
  def resolved_template_body_params
    (additional_attributes['template_body_params'] || {}).transform_values { |v| resolve_merge_tags(v) }
  end

  # True when a required body variable resolves to blank for this contact (e.g. a
  # {{contact.full_name}} mapping but the contact has no name). Bulk sends skip
  # these leads instead of dispatching a template the WhatsApp API would reject.
  def chatwoot_template_missing_data?
    return false unless chatwoot_template?

    template = chatwoot_template_definition
    return false if template.nil?

    body = Array(template['components']).find { |c| c['type'] == 'BODY' }
    required = body.to_h['text'].to_s.scan(/\{\{(\d+)\}\}/).flatten
    raw = additional_attributes['template_body_params'] || {}
    # Only a merge tag that resolves to blank is a per-lead data gap; a blank
    # fixed-text value is a configuration mistake caught by validation instead.
    required.any? { |n| merge_tag?(raw[n]) && resolve_merge_tags(raw[n]).blank? }
  end

  def merge_tag?(value)
    value.is_a?(String) && value.include?('{{contact.')
  end

  # Replaces {{contact.<field>}} tokens with the contact's value. Supports the
  # standard fields and custom attributes via {{contact.custom.<key>}}.
  def resolve_merge_tags(value)
    return value unless merge_tag?(value)

    value.gsub(/\{\{\s*contact\.([a-z_]+(?:\.[A-Za-z0-9_ -]+)?)\s*\}\}/) do
      resolve_contact_field(Regexp.last_match(1))
    end
  end

  def resolve_contact_field(key)
    return '' if contact.blank?

    if key.start_with?('custom.')
      contact.custom_attributes.to_h[key.delete_prefix('custom.')].to_s
    elsif CONTACT_MERGE_FIELDS.include?(key)
      contact.public_send(key).to_s
    else
      ''
    end
  end

  def chatwoot_media_header?(header)
    header.present? && %w[IMAGE VIDEO DOCUMENT].include?(header['format'].to_s)
  end

  def store_resolved_template_content
    self.content = resolved_template_content
  end

  def validate_chatwoot_template
    template = chatwoot_template_definition
    return errors.add(:base, :chatwoot_template_not_found) if template.nil?

    components = Array(template['components'])
    body = components.find { |c| c['type'] == 'BODY' }
    body_params = additional_attributes['template_body_params'] || {}
    required = body.to_h['text'].to_s.scan(/\{\{(\d+)\}\}/).flatten
    errors.add(:base, :chatwoot_template_body_params_missing) if required.any? { |n| body_params[n].blank? }

    header = components.find { |c| c['type'] == 'HEADER' }
    if chatwoot_media_header?(header) && additional_attributes['template_header_media_url'].blank?
      errors.add(:base, :chatwoot_template_header_missing)
    end
  end

  def should_delivery_event_scheduled?
    !done? && (Time.current.in_time_zone > scheduled_at)
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

  scope :by_message_id, lambda { |message_id|
    where("additional_attributes ->> 'message_id' = ?", message_id)
  }

  enum kind: {
    'note': 'note',
    'evolution_api_message': 'evolution_api_message',
    'activity': 'activity',
    'chatwoot_message': 'chatwoot_message',
    'deal_stage_change': 'deal_stage_change',
    'deal_opened': 'deal_opened',
    'deal_won': 'deal_won',
    'deal_lost': 'deal_lost',
    'deal_reopened': 'deal_reopened',
    'deal_product_added': 'deal_product_added',
    'deal_product_removed': 'deal_product_removed'
  }

  enum status: { sent: 0, delivered: 1, read: 2, failed: 3 }

  before_validation do
    self.done = false if scheduled_at.present? && done.nil?
  end

  def icon_key
    if note?
      'menu-square'
    elsif activity?
      'calendar-check-2'
    elsif chatwoot_message?
      'message-circle'
    end
  end

  def editable?
    return true if %w[note activity].include?(kind)
    return true if %w[chatwoot_message evolution_api_message].include?(kind) && !done?

    false
  end

  def deal_updates?
    DEAL_UPDATE_KINDS.include?(kind)
  end

  def kind_message?
    chatwoot_message? || evolution_api_message?
  end

  def overdue?
    return false if done == true || scheduled_at.blank?

    DateTime.current > scheduled_at
  end

  def primary_date
    if scheduled_at.present?
      scheduled_at.iso8601
    else
      created_at.iso8601
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

  def has_media_attachment?
    attachment.present? && (attachment.image? || attachment.file? || attachment.video?)
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
