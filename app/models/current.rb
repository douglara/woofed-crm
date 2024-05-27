class Current < ActiveSupport::CurrentAttributes
  def account
    Account.first
  end
end
