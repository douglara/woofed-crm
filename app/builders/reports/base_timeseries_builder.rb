class Reports::BaseTimeseriesBuilder
  include TimezoneHelper
  include DateRangeHelper
  DEFAULT_GROUP_BY = 'month'.freeze

  attr_reader :account, :params

  def initialize(account, params)
    raise ArgumentError, 'account is required' unless account
    raise ArgumentError, 'params is required' unless params

    @account = account
    @params = params
  end

  def scope
    case params[:type].to_sym
    when :account
      account
    when :stage
      stage
    end
  end

  def stage
    @stage ||= Stage.find(params[:id])
  end

  def group_by
    @group_by ||= %w[day week month year hour].include?(params[:group_by]) ? params[:group_by] : DEFAULT_GROUP_BY
  end

  def timezone
    @timezone ||= timezone_name_from_offset(params[:timezone_offset])
  end
end
