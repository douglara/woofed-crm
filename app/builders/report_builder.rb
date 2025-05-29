class ReportBuilder
  include ActionView::Helpers::TranslationHelper

  DEFAULT_GROUP_BY = 'month'.freeze

  attr_reader :account, :params, :starts_date_range, :ends_date_range

  def initialize(account, params)
    @account = account
    @params = params
    set_date_range
  end

  def build(metric)
    return send(metric) if metric_valid?(metric)

    {}
  end

  private

  def metric_valid?(metric)
    %i[summary pipeline_summary].include?(metric)
  end

  def summary
    {
      summaries: build_summaries,
      column_chart_data: build_column_chart_data
    }
  end

  def pipeline_summary
    { funnel_chart_data: build_funnel_chart_data }
  end

  def set_date_range
    if params[:date_range].present?
      starts_str, ends_str = params[:date_range].split(' - ')
      @starts_date_range = Date.strptime(starts_str, '%d/%m/%Y')
      @ends_date_range = Date.strptime(ends_str, '%d/%m/%Y')
    else
      @starts_date_range = Date.today - 1.months
      @ends_date_range = Date.today
      params[:date_range] = "#{@starts_date_range.strftime('%d/%m/%Y')} - #{@ends_date_range.strftime('%d/%m/%Y')}"
    end
  end

  def date_range
    starts_date_range.beginning_of_day..ends_date_range.end_of_day
  end

  def build_summaries
    deals_by_created_at = Deal.where(created_at: date_range)
    deals_open = deals_by_created_at.open
    deals_won = Deal.where(won_at: date_range)
    deals_lost = Deal.where(lost_at: date_range)

    [
      {
        title: t('activerecord.models.deal.open_deals'),
        amount: deals_open.sum(:total_deal_products_amount_in_cents),
        count: deals_open.count
      },
      {
        title: t('activerecord.models.deal.created_deals'),
        amount: deals_by_created_at.sum(:total_deal_products_amount_in_cents),
        count: deals_by_created_at.count
      },
      {
        title: t('activerecord.models.deal.won_deals'),
        amount: deals_won.sum(:total_deal_products_amount_in_cents),
        count: deals_won.count
      },
      {
        title: t('activerecord.models.deal.lost_deals'),
        amount: deals_lost.sum(:total_deal_products_amount_in_cents),
        count: deals_lost.count
      }
    ]
  end

  def build_column_chart_data
    deals_won = Deal.where(won_at: date_range)
    deals_lost = Deal.where(lost_at: date_range)

    deals_won_grouped = deals_won.group_by_month(:won_at, format: '%b %Y').count
    deals_lost_grouped = deals_lost.group_by_month(:lost_at, format: '%b %Y').count

    months = (deals_won_grouped.keys + deals_lost_grouped.keys).uniq

    {
      categories: months,
      series: [
        {
          name: t('activerecord.models.deal.won_deals'),
          data: months.map { |month| deals_won_grouped[month] || 0 }
        },
        {
          name: t('activerecord.models.deal.lost_deals'),
          data: months.map { |month| deals_lost_grouped[month] || 0 }
        }
      ]
    }
  end

  def build_funnel_chart_data
    pipeline = Pipeline.find_by(id: params[:pipeline_id]) || Pipeline.first
    return {} if pipeline.blank?

    deals = pipeline.deals.where(created_at: date_range)
    grouped_by_stage = deals.group(:stage).count

    pipeline.stages.each_with_object(categories: [], series: [{ name: pipeline.name, data: [] }]) do |stage, hash|
      hash[:categories] << stage.name
      hash[:series][0][:data] << (grouped_by_stage[stage] || 0)
    end
  end
end
