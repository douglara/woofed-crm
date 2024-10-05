# == Schema Information
#
# Table name: deals
#
#  id                :bigint           not null, primary key
#  custom_attributes :jsonb
#  name              :string           default(""), not null
#  position          :integer          default(1), not null
#  status            :string           default("open"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  contact_id        :bigint           not null
#  pipeline_id       :bigint
#  stage_id          :bigint           not null
#
# Indexes
#
#  index_deals_on_contact_id   (contact_id)
#  index_deals_on_pipeline_id  (pipeline_id)
#  index_deals_on_stage_id     (stage_id)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (stage_id => stages.id)
#
class Deal < ApplicationRecord
  include Deal::Decorators
  include CustomAttributes

  belongs_to :contact
  belongs_to :stage
  belongs_to :pipeline
  acts_as_list scope: :stage
  has_many :events, dependent: :destroy
  has_many :activities
  has_many :contact_events, through: :primary_contact, source: :events
  has_many :deal_products, dependent: :destroy
  accepts_nested_attributes_for :contact

  enum status: { 'open': 'open', 'won': 'won', 'lost': 'lost' }

  FORM_FIELDS = [:name]

  before_validation do
    self.account = @current_account if account.blank? && @current_account.present?

    self.pipeline = stage.pipeline if pipeline.blank? && stage.present?

    self.stage = pipeline.stages.first if stage.blank? && pipeline.present?
  end
  after_destroy_commit { broadcast_remove_to :stages, target: self }

  after_update_commit lambda {
                        broadcast_updates
                      }
  after_create_commit lambda {
                        Stages::BroadcastUpdatesWorker.perform_async(stage.id, status)
                      }

  around_create :create_deal_and_event
  around_update :update_deal_and_create_event

  def broadcast_updates
    broadcast_replace_later_to self, partial: 'accounts/pipelines/deal', locals: { pipeline: }

    if previous_changes.except('updated_at').keys == ['position'] || previous_changes.empty?
      Stages::BroadcastUpdatesWorker.perform_async(stage.id,
                                                   status)
    end

    if previous_changes.except('updated_at').keys == ['status']
      previous_changes['status'].each do |status|
        Stages::BroadcastUpdatesWorker.perform_async(stage.id, status)
      end
    end

    return unless previous_changes.key?('stage_id')

    previous_changes['stage_id'].each do |stage_id|
      Stages::BroadcastUpdatesWorker.perform_async(stage_id, status)
    end
  end

  def update_deal_and_create_event
    transaction do
      yield
      create_event_based_on_changes
    end
  rescue ActiveRecord::RecordInvalid => e
    if e.record.is_a?(Deal)
      errors.add(:base, "#{Deal.model_name.human} #{e.message}")
    elsif e.record.is_a?(Event)
      errors.add(:base, "#{Event.model_name.human} #{e.message}")
    else
      errors.add(:base, "#{Deal.model_name.human} #{Event.model_name.human} #{e.message}")
    end
    raise ActiveRecord::Rollback
  end

  def create_event_based_on_changes
    if previous_changes.except('updated_at').keys == ['status']
      if status == 'won'
        Event.create!(
          deal: self,
          kind: 'deal_won',
          done: true,
          contact:,
          from_me: true,
          additional_attributes: {
            stage_id: stage.id,
            stage_name: stage.name,
            pipeline_id: pipeline.id,
            pipeline_name: pipeline.name,
            deal_name: name
          }
        )
      elsif status == 'lost'
        Event.create!(
          deal: self,
          kind: 'deal_lost',
          done: true,
          contact:,
          from_me: true,
          additional_attributes: {
            stage_id: stage.id,
            stage_name: stage.name,
            pipeline_id: pipeline.id,
            pipeline_name: pipeline.name,
            deal_name: name
          }
        )
      else
        Event.create!(
          deal: self,
          kind: 'deal_reopened',
          done: true,
          contact:,
          from_me: true,
          additional_attributes: {
            stage_id: stage.id,
            stage_name: stage.name,
            pipeline_id: pipeline.id,
            pipeline_name: pipeline.name,
            deal_name: name
          }
        )
      end
    end
    return unless previous_changes.key?('stage_id')

    old_stage_id, new_stage_id = previous_changes['stage_id']
    old_stage = Stage.find_by(id: old_stage_id) if old_stage_id
    new_stage = Stage.find_by(id: new_stage_id) if new_stage_id

    Event.create!(
      deal: self,
      kind: 'deal_stage_change',
      done: true,
      contact:,
      from_me: true,
      additional_attributes: {
        old_stage_id: old_stage.id,
        old_stage_name: old_stage.name,
        old_stage_pipeline_id: old_stage.pipeline.id,
        old_stage_pipeline_name: old_stage.pipeline.name,
        new_stage_id: new_stage.id,
        new_stage_name: new_stage.name,
        new_stage_pipeline_id: new_stage.pipeline.id,
        new_stage_pipeline_name: new_stage.pipeline.name,
        deal_name: name
      }
    )
  end

  def create_deal_and_event
    transaction do
      yield
      Event.create!(
        deal: self,
        kind: 'deal_opened',
        done: true,
        from_me: true,
        contact:,
        additional_attributes: {
          stage_id: stage.id,
          stage_name: stage.name,
          pipeline_id: pipeline.id,
          pipeline_name: pipeline.name,
          deal_name: name
        }
      )
    end
  rescue ActiveRecord::RecordInvalid => e
    if e.record.is_a?(Deal)
      errors.add(:base, "#{Deal.model_name.human} #{e.message}")
    elsif e.record.is_a?(Event)
      errors.add(:base, "#{Event.model_name.human} #{e.message}")
    else
      errors.add(:base, "#{Deal.model_name.human} #{Event.model_name.human} #{e.message}")
    end
    raise ActiveRecord::Rollback
  end

  def next_event_planned?
    next_event_planned
  rescue StandardError
    false
  end

  def next_event_planned
    events.planned.first
  rescue StandardError
    nil
  end

  def self.csv_header(account_id)
    custom_fields = CustomAttributeDefinition.where(attribute_model: 'deal_attribute').map do |i|
      "custom_attributes.#{i.attribute_key}"
    end
    column_names.excluding('account_id', 'created_at', 'updated_at', 'id', 'custom_attributes') + custom_fields
  end

  ## Events

  include Wisper::Publisher
  after_commit :publish_created, on: :create
  after_commit :publish_updated, on: :update

  private

  def publish_created
    broadcast(:deal_created, self)
  end

  def publish_updated
    broadcast(:deal_updated, self)
  end
end
