class Reports::Deals::SummaryBuilder
  include DateRangeHelper

  def initialize(account, params)
    raise ArgumentError, 'account is required' unless account
    raise ArgumentError, 'params is required' unless params

    @account = account
    @params = params
    set_date_range
  end

  def build
    load_data
    prepare_report
  end

  private

  attr_reader :summary_name,
              :amount_sum, :quantity, :params, :account

  def load_data
    @summary_name = fetch_summary_name
    @amount_sum = fetch_amount_sum
    @quantity = fetch_quantity
  end

  def prepare_report
    {
      title: summary_name,
      amount_in_cents: amount_sum,
      quantity:
    }
  end

  def metric
    @metric ||= params[:metric]
  end

  def fetch_summary_name
    case metric.to_sym
    when :open
      I18n.t('activerecord.models.deal.open_deals')
    when :lost
      I18n.t('activerecord.models.deal.lost_deals')
    when :won
      I18n.t('activerecord.models.deal.won_deals')
    when :all
      I18n.t('activerecord.models.deal.created_deals')
    end
  end

  def fetch_amount_sum
    params_sum = params.merge(metric: "#{metric}_deals_sum")
    Reports::Deals::ReportBuilder.new(account, params_sum).aggregate_value
  end

  def fetch_quantity
    params_count = params.merge(metric: "#{metric}_deals_count")
    Reports::Deals::ReportBuilder.new(account, params_count).aggregate_value
  end
end
