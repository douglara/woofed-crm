class Account < ApplicationRecord
  validates :name, presence: true
  validates :name, length: { maximum: 255 }

  has_many :users, dependent: :destroy_async
  has_many :custom_attributes_definitions, class_name: 'CustomAttributeDefinition', dependent: :destroy_async

end
