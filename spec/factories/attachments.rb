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
FactoryBot.define do
  factory :attachment do
    attachable { nil }
    file_type { 1 }
  end
end
