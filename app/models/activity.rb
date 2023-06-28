# == Schema Information
#
# Table name: activities
#
#  id         :bigint           not null, primary key
#  done       :boolean          default(FALSE), not null
#  due        :datetime
#  name       :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
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

  after_commit :check_and_enqueue_whatsapp_message

  def check_and_enqueue_whatsapp_message
    if self.activity_kind.key == 'whatsapp' && self.previous_changes.has_key?('done') && self.done == true
      Activities::Whatsapp::Message::SendWorker.perform_in(1.seconds, self.id)
    end
  end
end
