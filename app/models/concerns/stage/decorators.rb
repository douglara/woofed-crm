module Stage::Decorators
  include ActionView::Helpers::NumberHelper

  def total_quantity_deals_resume(filter_status_deal)
    number_to_human(total_quantity_deals(filter_status_deal), units: { thousand: 'K', million: 'M', billion: 'B' })
  end
end
