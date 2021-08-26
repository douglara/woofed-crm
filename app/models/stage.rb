class Stage < ApplicationRecord
  belongs_to :pipeline
  has_many :deals
end
