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
#  account_id        :bigint           not null
#  contact_id        :bigint           not null
#  pipeline_id       :bigint
#  stage_id          :bigint           not null
#
# Indexes
#
#  index_deals_on_account_id   (account_id)
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
  belongs_to :account

  # has_and_belongs_to_many :contacts
  # has_many :contacts_deals
  # has_many :contacts, through: :contacts_deals

  # has_one :contacts_deal_main, -> { where(main: true) }, class_name: 'ContactsDeal'
  # has_one :contact_main, through: :contacts_deal_main, source: :contact
  # # has_one :primary_contact, through: :contacts_deal_main, source: :contact
  # has_one :primary_contact, through: :contacts_deal_main, source: :contact

  belongs_to :stage
  belongs_to :pipeline
  acts_as_list scope: :stage
  has_many :events, dependent: :destroy
  has_many :flow_items
  has_many :notes, through: :flow_items
  has_many :activities
  has_many :contact_events, through: :primary_contact, source: :events
  has_many :deal_products, dependent: :destroy
  accepts_nested_attributes_for :contact
  # accepts_nested_attributes_for :contacts
  # accepts_nested_attributes_for :contacts_deals

  enum status: { 'open': 'open', 'won': 'won', 'lost': 'lost' }

  FORM_FIELDS = [:name]

  before_validation do
    # if self.contact_main.blank?
    #   self.contact_main = self.contact
    # end

    # if self.contact.blank?
    #   self.contact = self.contacts.first
    # end

    self.account = @current_account if account.blank? && @current_account.present?

    self.pipeline = stage.pipeline if pipeline.blank? && stage.present?

    self.stage = pipeline.stages.first if stage.blank? && pipeline.present?
  end
  after_destroy_commit { broadcast_remove_to stage, target: self }

  after_update_commit -> { broadcast_updates }
  after_create_commit lambda {
                        broadcast_replace_later_to stage, target: stage,
                                                          partial: 'accounts/pipelines/stage',
                                                          locals: { stage: stage, status: 'all' }
                      }

  def broadcast_updates
    broadcast_replace_later_to self, partial: 'accounts/pipelines/deal', locals: { pipeline: pipeline }
    if previous_changes.key?('stage_id')
      previous_changes['stage_id'].each do |stage_id|
        Stage.find(stage_id).broadcast_updates
      end
    end
  end
  # validate :validate_contact_main

  # def validate_contact_main
  #   if self.contact != self.contact_main
  #     errors.add :base, 'Contact main invalid'
  #   end
  # end

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
    custom_fields = CustomAttributeDefinition.where(account_id: account_id,
                                                    attribute_model: 'deal_attribute').map do |i|
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
