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
FactoryBot.define do
  factory :attachment do
    event { nil }
    file_type { 1 }
  end
end
