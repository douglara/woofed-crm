# == Schema Information
#
# Table name: events
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  app_type              :string
#  custom_attributes     :jsonb
#  done                  :boolean
#  done_at               :datetime
#  from_me               :boolean
#  kind                  :string           default("note"), not null
#  scheduled_at          :datetime
#  status                :integer
#  title                 :string           default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#  app_id                :bigint
#  contact_id            :bigint
#  deal_id               :bigint
#
# Indexes
#
#  index_events_on_account_id  (account_id)
#  index_events_on_app         (app_type,app_id)
#  index_events_on_contact_id  (contact_id)
#  index_events_on_deal_id     (deal_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
FactoryBot.define do
  factory :event do
    account
    contact
    deal
    title { 'Event 1' }
    content { 'Hi Lorena' }
  end
end
