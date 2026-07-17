# == Schema Information
#
# Table name: companies
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  custom_attributes     :jsonb
#  email                 :string           default(""), not null
#  name                  :string           default(""), not null
#  phone                 :string           default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_companies_on_lower_email  (lower(NULLIF((email)::text, ''::text))) UNIQUE
#  index_companies_on_phone        (NULLIF((phone)::text, ''::text)) UNIQUE
#
class Company < ApplicationRecord
  include CustomAttributes
  include Labelable
  include Attachable
  include Company::ValidateDuplicateCompanies

  has_many :company_contacts, dependent: :destroy
  has_many :contacts, through: :company_contacts
  has_many :deal_companies, dependent: :destroy
  has_many :deals, through: :deal_companies

  validates :name, presence: true
  # Uniqueness of email/phone is enforced by the unique indexes and translated into
  # errors by ValidateDuplicateCompanies, so a concurrent insert cannot slip through.
  validates :email, allow_blank: true,
                    format: { with: Devise.email_regexp,
                              message: I18n.t('activerecord.errors.company.email.invalid',
                                              locale: I18n.locale) }
  validates :phone, allow_blank: true,
                    format: { with: /\+[1-9]\d{1,14}\z/,
                              message: I18n.t('activerecord.errors.company.phone.invalid',
                                              locale: I18n.locale) }

  FORM_FIELDS = %i[name phone email label_list].freeze

  SHOW_FIELDS = { details: %i[name phone email id label_list custom_attributes created_at updated_at] }.freeze

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name phone email created_at updated_at custom_attributes additional_attributes]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[labels contacts attachments deals]
  end

  def phone=(value)
    value = "+#{value}" if value.present? && !value.start_with?('+')
    super(value)
  end
end
