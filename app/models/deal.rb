class Deal < ApplicationRecord
  include Deal::Decorators

  belongs_to :contact

  #has_and_belongs_to_many :contacts
  has_many :contacts_deals
  has_many :contacts, through: :contacts_deals

  has_one :contacts_deal_main, -> { where(main: true) }, class_name: 'ContactsDeal'
  has_one :contact_main, through: :contacts_deal_main, source: :contact

  belongs_to :stage
  has_many :flow_items
  has_many :notes, through: :flow_items
  has_many :activities
  accepts_nested_attributes_for :contact

  enum status: { 'open': 'open', 'won': 'won', 'lost': 'lost' }

  before_validation do
    if self.contact_main.blank?
      self.contact_main = self.contact
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
end
