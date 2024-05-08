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
  def media_file?(file_content_type)
    file_content_type.start_with?('image/', 'video/', 'audio/')
  end

  def check_file_type
    if media_file?(file.content_type)
      file.content_type.split('/').first
    else
      'file'
    end
  end

  def file_download
    file_url = Rails.application.routes.url_helpers.rails_blob_url(file)
    file_temp = Down.download(file_url)
    FileUtils.mv(file_temp.path, "tmp/#{file_temp.original_filename}")
    File.open("tmp/#{file_temp.original_filename}")
  end

  def download_url
    file.attached? ? Rails.application.routes.url_helpers.rails_blob_url(file) : ''
  end
end
