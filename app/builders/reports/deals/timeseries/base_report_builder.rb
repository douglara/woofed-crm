class Reports::Deals::Timeseries::BaseReportBuilder < Reports::BaseTimeseriesBuilder
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

  private

  def grouped_count
    # Override this method
  end

  def metric
    filtered_metric = params[:metric].gsub(/_(sum|count)\z/, '')
    @metric ||= filtered_metric
  end

  def object_scope
    scope = send("scope_for_#{metric}")

    Query::Filter.new(scope, params[:filter]).call
  end

  def scope_for_won_deals
    scope.deals.won.where(won_at: range)
  end

  def scope_for_lost_deals
    scope.deals.lost.where(lost_at: range)
  end

  def scope_for_open_deals
    scope.deals.open.where(created_at: range)
  end

  def scope_for_all_deals
    scope.deals.where(created_at: range)
  end

  def grouping_field
    case metric.to_sym
    when :won_deals
      :won_at
    when :lost_deals
      :lost_at
    else
      :created_at
    end
  end
end
