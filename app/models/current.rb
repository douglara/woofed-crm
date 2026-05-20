class Current < ActiveSupport::CurrentAttributes
  attribute :user

  def account
    Account.first
  end
end
