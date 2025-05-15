module DealProduct::HandleInCentsValues
  extend ActiveSupport::Concern
  included do
    def unit_amount_in_cents=(amount)
      amount = sanitize_amount(amount)
      super(amount)
    end
  end
end
