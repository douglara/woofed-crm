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
#  app_id                :bigint
#
# Indexes
#
#  index_contacts_on_app          (app_type,app_id)
#  index_contacts_on_lower_email  (lower(NULLIF((email)::text, ''::text))) UNIQUE
#  index_contacts_on_phone        (NULLIF((phone)::text, ''::text)) UNIQUE
#
class Contact < ApplicationRecord
  include Labelable
  include ChatwootLabels
  include CustomAttributes
  include Contact::Presenters

  has_many :events

  attr_accessor :skip_validation

  validates :email, allow_blank: true, uniqueness: { case_sensitive: false },
                    format: { with: Devise.email_regexp,
                              message: I18n.t('activerecord.errors.contact.email.invalid',
                                              locale: I18n.locale) }, unless: :skip_validation

  validates :phone, allow_blank: true, uniqueness: true,
                    format: { with: /\+[1-9]\d{1,14}\z/,
                              message: I18n.t('activerecord.errors.contact.phone.invalid',
                                              locale: I18n.locale) }, unless: :skip_validation

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

  SHOW_FIELDS = { details: %i[full_name email phone id label_list chatwoot_conversations_label_list custom_attributes created_at
                              updated_at],
                  deal_page_overview_details: %i[full_name email phone label_list
                                                 chatwoot_conversations_label_list] }.freeze

  after_commit :export_contact_to_chatwoot, on: %i[create update], unless: :skip_validation

  def phone=(value)
    value = "+#{value}" if value.present? && !value.start_with?('+')
    super(value)
  end

  ## Events

  include Wisper::Publisher
  after_commit :publish_created, on: :create, unless: :skip_validation
  after_commit :publish_updated, on: :update, unless: :skip_validation

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
