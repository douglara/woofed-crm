class Reports::Deals::Charts::Timeseries::DealsCount
  def initialize(account, params)
    @account = account

    @report_params = {
                        metric: 'won_deals_count',
                        since: params[:since].to_time.to_i.to_s,
                        until: params[:until].to_time.to_i.to_s,
                        timezone_offset: params[:timezone_offset],
                        type: params[:type]&.to_sym,
                        id: params[:id],
                        group_by: params[:group_by]
                      }
  end

  def call
    {
      chart_type: 'column',
      data: [
        { name: I18n.t('activerecord.models.deal.won_deals'),
          color: metric_color('won_deals'),
          series_data: Reports::Deals::ReportBuilder.new(Current.account,
                                                                        @report_params.merge(metric: 'won_deals_count')).timeseries },
        { name: I18n.t('activerecord.models.deal.lost_deals'),
          color: metric_color('lost_deals'),
          series_data: Reports::Deals::ReportBuilder.new(Current.account,
                                                                         @report_params.merge(metric: 'lost_deals_count')).timeseries }

      ]
    }.to_json
  end

  private

  def metric_color(metric)
    case metric
    when 'lost_deals'
      '#CF4F27'
    when 'won_deals'
      '#259C50'
    when 'open_deals'
      '#5491F5'
    else
      '#6857D9'
    end
  end
end
