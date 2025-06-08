class Reports::Deals::BaseReportBuilder
  def initialize(account, params)
    raise ArgumentError, 'account is required' unless account
    raise ArgumentError, 'params is required' unless params

    @account = account
    @params = params
  end

  private

  attr_reader :account, :params

  COUNT_METRICS = %w[
    won_deals_count
    lost_deals_count
    open_deals_count
    all_deals_count
  ].freeze

  SUM_METRICS = %w[
    won_deals_sum
    lost_deals_sum
    open_deals_sum
    all_deals_sum
  ].freeze

  def builder_class(metric)
    case metric
    when *COUNT_METRICS
      Reports::Deals::Timeseries::CountReportBuilder
    when *SUM_METRICS
      Reports::Deals::Timeseries::SumReportBuilder
    end
  end

  def log_invalid_metric
    Rails.logger.error "ReportBuilder: Invalid metric - #{params[:metric]}"

    {}
  end
end
