class Accounts::ReportsController < InternalController
  before_action :set_date_range

  def index
    @users = User.all
  end

  def summary
    @deal_summary = build_deal_sumary
    @deals_timeseries_count = build_chart_deals_timeseries_body
  end

  def pipeline_summary
    pipeline_id = params[:pipeline_id].presence || Pipeline.first&.id

    if pipeline_id
      series_data = Reports::Pipeline::StagesMetricBuilder.new(Current.account, report_params.merge(id: pipeline_id)).metrics
      @pipeline_summary = build_chart_pipeline_summary_body(series_data)
    else
      @pipeline_summary = {}
    end
  end

  private

  def build_deal_sumary
    [
      Reports::Deals::MetricBuilder.new(Current.account, report_params.merge(metric: 'open_deals')).summary,
      Reports::Deals::MetricBuilder.new(Current.account, report_params.merge(metric: 'all_deals')).summary,
      Reports::Deals::MetricBuilder.new(Current.account, report_params.merge(metric: 'won_deals')).summary,
      Reports::Deals::MetricBuilder.new(Current.account, report_params.merge(metric: 'lost_deals')).summary
    ]
  end

  def report_params
    common_params.merge({
                          metric: params[:metric],
                          since: params[:since].to_time.to_i.to_s,
                          until: params[:until].to_time.to_i.to_s,
                          timezone_offset: params[:timezone_offset]
                        })
  end

  def common_params
    {
      type: params[:type]&.to_sym,
      id: params[:id],
      group_by: params[:group_by],
      filter: params[:filter]&.to_unsafe_h
    }
  end

  def build_chart_deals_timeseries_body
    {
      chart_type: 'column',
      data: [
        { name: I18n.t('activerecord.models.deal.won_deals'),
          color: metric_color('won_deals'),
          series_data: Reports::Deals::ReportBuilder.new(Current.account,
                                                                        report_params.merge(metric: 'won_deals_count')).timeseries },
        { name: I18n.t('activerecord.models.deal.lost_deals'),
          color: metric_color('lost_deals'),
          series_data: Reports::Deals::ReportBuilder.new(Current.account,
                                                                         report_params.merge(metric: 'lost_deals_count')).timeseries }

      ]
    }.to_json
  end

  def build_chart_pipeline_summary_body(series_data)
    {
      chart_type: 'funnel',
      data: [
        { name: Deal.model_name.human,
          color: metric_color(params[:metric]),
          series_data: series_data
        }
      ]
    }.to_json
  end

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

  def set_date_range
    if params[:date_range].present?
      starts_str, ends_str = params[:date_range].split(' - ')
      params[:since] = starts_str
      params[:until] = ends_str
    else
      params[:date_range] = "#{params[:since]} - #{params[:until]}"
    end
  end
end
