class Activity < ApplicationRecord
  include Activity::Decorators

  belongs_to :activity_kind
  has_rich_text :content
  has_one :flow_item, as: :record

  accepts_nested_attributes_for :flow_item

  scope :not_done, -> { where(done: false) }

  def overdue?
    return false if due.blank?
    DateTime.now < due
  end
end
