class Reports::Deals::Timeseries::WonDeals < Reports::Deals::Timeseries::BaseReportBuilder
  def aggregate_value
    object_scope.count
  end

  def object_scope
    scope.deals.won.where(won_at: range)
  end

  def grouping_field
    :won_at
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
    ).count
  end
end
