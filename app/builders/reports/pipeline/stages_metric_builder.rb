class Reports::Pipeline::StagesMetricBuilder
  include DateRangeHelper

  def initialize(account, params)
    raise ArgumentError, 'account is required' unless account
    raise ArgumentError, 'params is required' unless params

    @account = account
    @params = params
  end

  def metrics
    return build_metrics if valid_deal_status?

    raise ArgumentError, 'invalid metric'
  end

  private

  attr_reader :account, :params

  def pipeline
    @pipeline ||= Pipeline.find(params[:id])
  end

  def valid_deal_status?
    %i[won_deals lost_deals open_deals all_deals].include?(params[:metric]&.to_sym)
  end

  def build_metrics
    pipeline.stages.order(:position).each_with_object({}) do |stage, hash|
      params_stage = params.merge(metric: "#{params[:metric]}_count", id: stage.id, type: :stage)
      hash[stage.name] = Reports::Deals::ReportBuilder.new(account, params_stage).aggregate_value
    end
  end
end
