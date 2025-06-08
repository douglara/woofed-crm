class Reports::Deals::Timeseries::CountReportBuilder < Reports::BaseTimeseriesBuilder
  def timeseries
    grouped_count.each_with_object([]) do |element, arr|
      event_date, event_count = element

      # The `event_date` is in Date format (without time), such as "Wed, 15 May 2024".
      # We need a timestamp for the start of the day. However, we can't use `event_date.to_time.to_i`
      # because it converts the date to 12:00 AM server timezone.
      # The desired output should be 12:00 AM in the specified timezone.
      arr << { value: event_count, timestamp: event_date.in_time_zone(timezone).to_i }
    end
  end

  def aggregate_value
    object_scope.count
  end

  private

  def metric
    @metric ||= params[:metric]
  end

  def object_scope
    send("scope_for_#{metric}")
  end

  def scope_for_won_deals_count
    scope.deals.won.where(won_at: range)
  end

  def scope_for_lost_deals_count
    scope.deals.lost.where(lost_at: range)
  end

  def scope_for_open_deals_count
    scope.deals.open.where(created_at: range)
  end

  def scope_for_all_deals_count
    scope.deals.where(created_at: range)
  end

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

  def grouping_field
    case params[:metric].to_sym
    when :deals_won_count
      :won_at
    when :deals_lost_count
      :lost_at
    else
      :created_at
    end
  end
end
