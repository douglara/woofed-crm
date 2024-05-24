# == Schema Information
#
# Table name: contacts
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  app_type              :string
#  custom_attributes     :jsonb
#  email                 :string           default(""), not null
#  full_name             :string           default(""), not null
#  phone                 :string           default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#  app_id                :bigint
#
# Indexes
#
#  index_contacts_on_account_id  (account_id)
#  index_contacts_on_app         (app_type,app_id)
#
class Contact < ApplicationRecord
  include Labelable
  include ChatwootLabels
  include CustomAttributes

  validates :full_name, presence: true
  has_many :flow_items
  has_many :events
  belongs_to :account
  validates :phone,
            allow_blank: true,
            format: { with: /\+[1-9]\d{1,14}\z/ }

  has_many :deals, dependent: :destroy
  belongs_to :app, polymorphic: true, optional: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[additional_attributes app_id app_type created_at custom_attributes email full_name id
       phone updated_at]
  end

  def connected_with_chatwoot?
    additional_attributes['chatwoot_id'].present?
  end

  FORM_FIELDS = %i[full_name email phone label_list chatwoot_conversations_label_list]
  after_commit :export_contact_to_chatwoot, on: %i[create update]

  def phone=(value)
    value = "+#{value}" if value.present? && !value.start_with?('+')
    super(value)
  end

  ## Events

  include Wisper::Publisher
  after_commit :publish_created, on: :create
  after_commit :publish_updated, on: :update

  private

  def export_contact_to_chatwoot
    account.apps_chatwoots.present? && Accounts::Apps::Chatwoots::ExportContactWorker.perform_async(
      account.apps_chatwoots.first.id, id
    )
  end

  def publish_created
    broadcast(:contact_created, self)
  end

  def publish_updated
    broadcast(:contact_updated, self)
  end
end
