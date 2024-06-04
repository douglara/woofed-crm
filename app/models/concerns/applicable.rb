module Applicable
  extend ActiveSupport::Concern
  included do
    belongs_to :account, optional: true
    attribute :account_id

    def account
      Current.account
    end

    def account_id
      Current.account&.id
    end
  end
end
