# == Schema Information
#
# Table name: attachments
#
#  id              :bigint           not null, primary key
#  attachable_type :string           not null
#  file_type       :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  attachable_id   :bigint           not null
#
# Indexes
#
#  index_attachments_on_attachable  (attachable_type,attachable_id)
#
class Attachment < ApplicationRecord
  ACCEPTABLE_FILE_TYPES = %w[
    text/csv text/plain text/rtf
    application/json application/pdf
    application/zip application/x-7z-compressed application/vnd.rar application/x-tar
    application/msword application/vnd.ms-excel application/vnd.ms-powerpoint application/rtf
    application/vnd.oasis.opendocument.text
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.openxmlformats-officedocument.wordprocessingml.document application/x-rar-compressed;version=5
  ].freeze

  belongs_to :attachable, polymorphic: true
  has_one_attached :file
  validates :file, presence: true
  validate :acceptable_file
  enum file_type: { image: 0, audio: 1, video: 2, file: 3, location: 4, fallback: 5, share: 6, story_mention: 7,
                    contact: 8 }

  before_validation :fill_file_type

  def media_file?(file_content_type)
    file_content_type.start_with?('image/', 'video/', 'audio/')
  end

  scope :by_file_type, ->(file_type) { where(file_type: file_types[file_type]) }

  def check_file_type
    if media_file?(file.content_type)
      file.content_type.split('/').first
    elsif ACCEPTABLE_FILE_TYPES.include?(file.content_type)
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

  def fill_file_type
    self.file_type = check_file_type if file_type.blank?
  end

  def acceptable_file
    errors.add(:file, I18n.t('activerecord.errors.messages.file_type_not_supported')) if file_type.blank?
    errors.add(:file, I18n.t('activerecord.errors.messages.file_size_too_big')) if acceptable_file_size
  end

  def acceptable_file_size
    file.byte_size > 40.megabytes
  end
end
