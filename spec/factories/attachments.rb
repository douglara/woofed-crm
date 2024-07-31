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
FactoryBot.define do
  factory :attachment do
    trait :for_product do
      association :attachable, factory: :product
    end
    trait :image do
      file_type { 'image' }
      file { Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/files/patrick.png") }
    end
  end
end
