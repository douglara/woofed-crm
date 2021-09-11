class FlowItem < ApplicationRecord
  default_scope { order(created_at: :desc) }

  belongs_to :deal
  belongs_to :contact
  belongs_to :record, polymorphic: true, dependent: :destroy

  scope :activities_not_done, -> {
    joins("LEFT JOIN activities ON activities.id = flow_items.record_id")
    .where('activities.done = False').where(record_type: 'Activity')
  }

  scope :wihtout_activities_not_done, -> { where.not(id: activities_not_done) }
end
