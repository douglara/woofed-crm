# == Schema Information
#
# Table name: attachments
#
#  id              :bigint           not null, primary key
#  attachable_type :string           not null
#  file_type       :integer          default("image"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  attachable_id   :bigint           not null
#
# Indexes
#
#  index_attachments_on_attachable  (attachable_type,attachable_id)
#
class Attachment < ApplicationRecord
  belongs_to :attachable, polymorphic: true
  has_one_attached :file
  validates :file, presence: true
  enum file_type: { image: 0, audio: 1, video: 2, file: 3, location: 4, fallback: 5, share: 6, story_mention: 7,
                    contact: 8 }
end
