class Reports::Deals::MetricBuilder < Reports::Deals::BaseReportBuilder
  def summary
    {
      title: fetch_summary_name,
      amount_in_cents: count("#{params[:metric]}_sum"),
      quantity: count("#{params[:metric]}_count")
    }
  end

  private

  def count(metric)
    builder_class(metric).new(account, builder_params(metric)).aggregate_value
  end

  def builder_params(metric)
    params.merge({ metric: })
  end

  def fetch_summary_name
    case params[:metric].to_sym
    when :open_deals
      I18n.t('activerecord.models.deal.open_deals')
    when :lost_deals
      I18n.t('activerecord.models.deal.lost_deals')
    when :won_deals
      I18n.t('activerecord.models.deal.won_deals')
    when :all_deals
      I18n.t('activerecord.models.deal.created_deals')
    end
  end
end
