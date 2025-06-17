class Accounts::ReportsController < InternalController
  before_action :set_date_range

  def index
  end

  def summary
    @deal_summary = build_deal_sumary
    @won_deals_timeseries_count = Reports::Deals::ReportBuilder.new(Current.account,
                                                                    report_params.merge(metric: 'won_deals_count')).timeseries
    @lost_deals_timeseries_count = Reports::Deals::ReportBuilder.new(Current.account,
                                                                     report_params.merge(metric: 'lost_deals_count')).timeseries
  end

  def pipeline_summary
    if params[:pipeline_id].present?
      @pipeline_summary = Reports::Pipeline::StagesMetricBuilder.new(Current.account,
                                                                     report_params.merge(id: params[:pipeline_id])).metrics
    elsif Pipeline.first.present?
      @pipeline_summary = Reports::Pipeline::StagesMetricBuilder.new(Current.account,
                                                                     report_params.merge(id: Pipeline.first&.id)).metrics
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
      group_by: params[:group_by]
    }
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
