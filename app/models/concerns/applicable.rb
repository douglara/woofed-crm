module Applicable
  extend ActiveSupport::Concern
  included do
    validates :account_id, presence: true
    belongs_to :account
  end

end