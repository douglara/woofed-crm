# == Schema Information
#
# Table name: embedding_documments
#
#  id               :bigint           not null, primary key
#  content          :text
#  embedding        :vector(1536)
#  source_reference :string
#  source_type      :string
#  status           :integer          default(0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  source_id        :bigint
#
# Indexes
#
#  index_embedding_documments_on_source  (source_type,source_id)
#
FactoryBot.define do
  factory :embedding_documment do
  end
end
