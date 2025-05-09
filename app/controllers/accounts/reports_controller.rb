class Accounts::ReportsController < InternalController
  def index
  end

  def summary
    if params[:date_range]
      starts = params[:date_range].split(' - ').first
      starts_date_range = Date.strptime(starts, '%d/%m/%Y')
      ends = params[:date_range].split(' - ').second
      ends_date_range = Date.strptime(ends, '%d/%m/%Y')
      @deals_by_created_at = Deal.where(created_at: starts_date_range.beginning_of_day..ends_date_range.end_of_day)
      @deals_open = @deals_by_created_at.open
      @deals_won = Deal.where(won_at: starts_date_range.beginning_of_day..ends_date_range.end_of_day)
      @deals_lost = Deal.where(lost_at: starts_date_range.beginning_of_day..ends_date_range.end_of_day)

      @summaries = [
        {
          title: t("activerecord.models.deal.open_deals"),
          amount: @deals_open.sum(:total_deal_products_amount_in_cents),
          count: @deals_open.count
        },
        {
          title: t("activerecord.models.deal.created_deals"),
          amount: @deals_by_created_at.sum(:total_deal_products_amount_in_cents),
          count: @deals_by_created_at.count
        },
        {
          title: t("activerecord.models.deal.won_deals"),
          amount: @deals_won.sum(:total_deal_products_amount_in_cents),
          count: @deals_won.count
        },
        {
          title: t("activerecord.models.deal.lost_deals"),
          amount: @deals_lost.sum(:total_deal_products_amount_in_cents),
          count: @deals_lost.count
        },
      ]

      @deals_won_grouped_by_month = @deals_won.group_by_month(:won_at, format: '%b %Y').count
      @deals_lost_grouped_by_month = @deals_lost.group_by_month(:lost_at, format: '%b %Y').count

      column_chart_months = (@deals_won_grouped_by_month.keys + @deals_lost_grouped_by_month.keys).uniq
      @column_chart_data = {
        categories: column_chart_months,
        series: [
          {
            name: t("activerecord.models.deal.won_deals"),
            data: column_chart_months.map { |month| @deals_won_grouped_by_month[month] || 0 },
          },
          {
            name: t("activerecord.models.deal.lost_deals"),
            data: column_chart_months.map { |month| @deals_lost_grouped_by_month[month] || 0 },
          },
        ],
      }
    end
  end

  def pipeline_summary
    if params[:pipeline_id]
      pipeline = Pipeline.find(params[:pipeline_id])
    else
      pipeline = Pipeline.first
    end

    starts = params[:date_range].split(' - ').first
    starts_date_range = Date.strptime(starts, '%d/%m/%Y')
    ends = params[:date_range].split(' - ').second
    ends_date_range = Date.strptime(ends, '%d/%m/%Y')


    @deals = pipeline.deals.where(created_at: starts_date_range.beginning_of_day..ends_date_range.end_of_day)

    grouped_by_stage = @deals.group(:stage).count

    @funnel_chart_data = pipeline.stages.each_with_object(categories: [], series: [{ name: pipeline.name, data: [] }]) do |stage, hash|
      hash[:categories] << stage.name
      hash[:series][0][:data] << (grouped_by_stage[stage] || 0)
    end
  end
end
