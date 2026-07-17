module Attachable
  extend ActiveSupport::Concern

  included do
    has_many :attachments, as: :attachable, dependent: :destroy
    accepts_nested_attributes_for :attachments, reject_if: :all_blank, allow_destroy: true

    %i[image file video].each do |file_type|
      define_method "#{file_type}_attachments" do
        attachments.by_file_type(file_type)
      end
    end
  end
end
