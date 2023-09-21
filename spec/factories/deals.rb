# == Schema Information
#
# Table name: deals
#
#  id                :bigint           not null, primary key
#  custom_attributes :jsonb
#  name              :string           default(""), not null
#  position          :integer          default(1), not null
#  status            :string           default("open"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  contact_id        :bigint           not null
#  pipeline_id       :bigint
#  stage_id          :bigint           not null
#
# Indexes
#
#  index_deals_on_account_id   (account_id)
#  index_deals_on_contact_id   (contact_id)
#  index_deals_on_pipeline_id  (pipeline_id)
#  index_deals_on_stage_id     (stage_id)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (stage_id => stages.id)
#
FactoryBot.define do
  factory :deal do
    account
    stage
    contact
    name { 'Deal 1' }
  end
end
