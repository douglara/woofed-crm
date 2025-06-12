##############################################
# Helpers to implement date range filtering to APIs
# Include in your controller or service class where params is available
##############################################

module DateRangeHelper
  def set_date_range
    # if params[:date_range].present?
    #   starts_str, ends_str = params[:date_range].split(' - ')
    #   params[:since] = Date.strptime(starts_str, '%d/%m/%Y')
    #   params[:until] = Date.strptime(ends_str, '%d/%m/%Y')
    # else
    #   params[:since] = Date.today - 1.months
    #   params[:until] = Date.today
    #   params[:date_range] = "#{params[:since].strftime('%d/%m/%Y')} - #{params[:until].strftime('%d/%m/%Y')}"
    # end
  end

  def range
    return if params[:since].blank? || params[:until].blank?

    parse_date_time(params[:since])...parse_date_time(params[:until])
  end

  def parse_date_time(datetime)
    return datetime if datetime.is_a?(DateTime)
    return datetime.to_datetime if datetime.is_a?(Time) || datetime.is_a?(Date)

    DateTime.strptime(datetime, '%s')
  end
end
