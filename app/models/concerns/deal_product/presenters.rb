module DealProduct::Presenters
  include ActionView::Helpers::NumberHelper
  extend ActiveSupport::Concern

  def total_amount_in_cents_at_format
    number_to_currency(total_amount_in_cents / 100.0, unit: 'R$', separator: ',', delimiter: '.')
  rescue StandardError
    ''
  end

  def unit_amount_in_cents_at_format
    number_to_currency(unit_amount_in_cents / 100.0, unit: 'R$', separator: ',', delimiter: '.')
  rescue StandardError
    ''
  end
end
