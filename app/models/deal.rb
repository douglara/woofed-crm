class Deal < ApplicationRecord
  include Deal::Decorators

  belongs_to :contact
  belongs_to :account

  #has_and_belongs_to_many :contacts
  has_many :contacts_deals
  has_many :contacts, through: :contacts_deals

  has_one :contacts_deal_main, -> { where(main: true) }, class_name: 'ContactsDeal'
  has_one :contact_main, through: :contacts_deal_main, source: :contact
  # has_one :primary_contact, through: :contacts_deal_main, source: :contact
  has_one :primary_contact, through: :contacts_deal_main, source: :contact

  belongs_to :stage
  has_many :events
  has_many :flow_items
  has_many :notes, through: :flow_items
  has_many :activities
  accepts_nested_attributes_for :contact
  accepts_nested_attributes_for :contacts
  accepts_nested_attributes_for :contacts_deals

  enum status: { 'open': 'open', 'won': 'won', 'lost': 'lost' }

  before_validation do
    if self.contact_main.blank?
      self.contact_main = self.contact
    end

    if self.contact.blank?
      self.contact = self.contacts.first
    end

    if self.account.blank? && @current_account.present?
      self.account = @current_account
    end
  end

  validate :validate_contact_main

  def validate_contact_main
    if self.contact != self.contact_main
      errors.add :base, 'Contact main invalid'
    end
  end

  def next_action?
    next_action rescue false
  end

  def next_action_overdue?
    return false unless next_action?
    DateTime.now > next_action
  end

  def next_action
    flow_items.activities_not_done.first.record.due rescue nil
  end

  def self.csv_header(account_id)
    custom_fields = CustomAttributeDefinition.where(account_id: account_id, attribute_model: 'deal_attribute').map { | i | "custom_attributes.#{i.attribute_key}" }
    self.column_names.excluding('account_id','created_at', 'updated_at', 'id', 'custom_attributes' ) + custom_fields
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
