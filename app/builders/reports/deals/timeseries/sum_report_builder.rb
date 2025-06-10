class Reports::Deals::Timeseries::SumReportBuilder < Reports::Deals::Timeseries::BaseReportBuilder
  def aggregate_value
    object_scope.sum(:total_deal_products_amount_in_cents)
  end

  private

  def grouped_count
    @grouped_values = object_scope.group_by_period(
      group_by,
      grouping_field,
      default_value: 0,
      range:,
      permit: %w[day week month year hour],
      time_zone: timezone
    ).sum(:total_deal_products_amount_in_cents)
  end
end
