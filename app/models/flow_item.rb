class FlowItem < ApplicationRecord
  default_scope { order(created_at: :desc) }

  belongs_to :deal, optional: true
  belongs_to :contact
  belongs_to :kind, polymorphic: true, dependent: :destroy, optional: true

  jsonb_accessor :item,
    name: [:string, default: ''],
    wp_connect_id: [:integer],
    due: [:datetime],
    done: [:boolean, default: false],
    source_id: [:string,],
    error: [:jsonb],
    content: [:text]

  scope :done_items, -> {
    item_where(done: true)
  }

  def due_format
    due.to_s(:short) rescue ''
  end
  
  def overdue?
    return false if self.done == true || due.blank?
    DateTime.now < due
  end
end
