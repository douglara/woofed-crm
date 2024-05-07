module Product::Presenters
  include ActionView::Helpers::NumberHelper
  extend ActiveSupport::Concern

  def amount_in_cents_at_format
    number_to_currency(amount_in_cents / 100.0, unit: 'R$', separator: ',', delimiter: '.')
  rescue StandardError
    ''
  end
end
