# == Schema Information
#
# Table name: accounts
#
#  id         :bigint           not null, primary key
#  name       :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Account < ApplicationRecord
  validates :name, presence: true
  validates :name, length: { maximum: 255 }

  has_many :events, dependent: :destroy_async
  has_many :apps, dependent: :destroy_async
  has_many :users, dependent: :destroy_async
  has_many :contacts, dependent: :destroy_async
  has_many :deals, dependent: :destroy_async
  has_many :custom_attribute_definitions
  has_many :custom_attributes_definitions, class_name: 'CustomAttributeDefinition', dependent: :destroy_async
  has_many :apps_wpp_connects, class_name: 'Apps::WppConnect'
  has_many :apps_chatwoots, class_name: 'Apps::Chatwoot'
  has_many :webhooks, dependent: :destroy
  has_many :pipelines, dependent: :destroy
  has_many :stages, dependent: :destroy

end
