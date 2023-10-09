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

  has_many :deals
  belongs_to :app, polymorphic: true, optional: true

  def connected_with_chatwoot?
    additional_attributes['chatwoot_id'].present?
  end

  FORM_FIELDS = [:full_name, :email, :phone]

  ## Events

  include Wisper::Publisher
  after_commit :publish_created, on: :create
  after_commit :publish_updated, on: :update

  private

  def publish_created
    broadcast(:contact_created, self)
  end

  def publish_updated
    broadcast(:contact_updated, self)
  end
end
