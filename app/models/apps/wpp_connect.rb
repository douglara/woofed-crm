class Apps::WppConnect < ApplicationRecord
  include Applicable

  scope :actives, -> { where(active: true) }
end
