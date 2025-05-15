module Deal::Presenters
  include ActionView::Helpers::NumberHelper
  extend ActiveSupport::Concern

  def total_deal_products_amount_in_cents_at_format
    number_to_currency(total_deal_products_amount_in_cents / 100.0, unit: 'R$', separator: ',', delimiter: '.')
  rescue StandardError
    ''
  end

  def total_amount_in_cents_at_format
    number_to_currency(total_amount_in_cents / 100.0, unit: 'R$', separator: ',', delimiter: '.')
  rescue StandardError
    ''
  end
end
