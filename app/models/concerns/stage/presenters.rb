module Stage::Presenters
  include ActionView::Helpers::NumberHelper
  extend ActiveSupport::Concern

  def total_amount_deals_at_format(filter_status_deal)
    number_to_currency(total_amount_deals(filter_status_deal) / 100.0, unit: 'R$', separator: ',', delimiter: '.')
  rescue StandardError
    ''
  end
end
