# == Schema Information
#
# Table name: attachments
#
#  id         :bigint           not null, primary key
#  file_type  :integer          default("image"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  event_id   :bigint           not null
#
# Indexes
#
#  index_attachments_on_event_id  (event_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#
class Attachment < ApplicationRecord
  belongs_to :event
  has_one_attached :file
  enum file_type: { image: 0, audio: 1, video: 2, file: 3, location: 4, fallback: 5, share: 6, story_mention: 7,
                    contact: 8 }
end
