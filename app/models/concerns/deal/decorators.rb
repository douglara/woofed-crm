module Deal::Decorators
  include ActionView::Helpers::NumberHelper

  def card_total_amount_resume
    number_to_human((total_amount_in_cents / 100.0), units: { thousand: 'K', million: 'M', billion: 'B' })
  end

  def card_total_amount_detail
    number_to_currency(
      (total_amount_in_cents / 100.0), separator: ',', delimiter: '.', precision: 2
    )
  end
end
