class Deal < ApplicationRecord
  include Deal::Decorators

  belongs_to :contact
  belongs_to :stage
  has_many :flow_items
  has_many :notes, through: :flow_items
  has_many :activities

  accepts_nested_attributes_for :contact

  enum status: { 'open': 'open', 'won': 'won', 'lost': 'lost' }

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
