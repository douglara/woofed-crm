class Reports::Pipeline::StageMetricBuilder
  include DateRangeHelper

  def initialize(account, params)
    raise ArgumentError, 'account is required' unless account
    raise ArgumentError, 'params is required' unless params

    @account = account
    @params = params
    set_date_range
  end

  def metrics
    return {} if pipeline.blank?

    deals_by_stage = fetch_deals_by_stage
    build_metrics(deals_by_stage)
  end

  private

  attr_reader :account, :params

  def valid_deal_status?
    %i[won open lost].include?(deal_status)
  end

  def pipeline
    @pipeline ||= Pipeline.find_by(id: params[:id])
  end

  def deals # Ta errado
    @deals ||= if valid_deal_status?
                 pipeline.deals.where(created_at: range, status: deal_status)
               else
                 pipeline.deals.where(created_at: range)
               end
  end

  def fetch_deals_by_stage
    deals.group(:stage).count
  end

  def deal_status
    params[:deal_status]&.to_sym
  end

  def build_metrics(deals_by_stage)
    {
      pipeline_name: pipeline.name,
      metrics: pipeline.stages.map do |stage|
        {
          name: stage.name,
          count: deals_by_stage[stage] || 0
        }
      end
    }
  end
end
