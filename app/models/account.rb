class Account < ApplicationRecord
  validates :name, presence: true
  validates :name, length: { maximum: 255 }

  has_many :users, dependent: :destroy_async

end
