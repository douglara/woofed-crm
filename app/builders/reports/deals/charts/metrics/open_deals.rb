class Reports::Deals::Charts::Metrics::OpenDeals
  def initialize(account, params)
    @account = account
    @report_params = {
                      metric: 'open_deals',
                      since: params[:since].to_time.to_i.to_s,
                      until: params[:until].to_time.to_i.to_s,
                      timezone_offset: params[:timezone_offset],
                      type: params[:type]&.to_sym,
                      id: params[:id],
                      group_by: params[:group_by]
                    }

  end

  def call
    Reports::Deals::MetricBuilder.new(@account, @report_params).summary
  end
end
