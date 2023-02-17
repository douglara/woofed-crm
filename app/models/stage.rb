class Stage < ApplicationRecord
  belongs_to :pipeline
  belongs_to :account
  has_many :deals, dependent: :destroy
end
