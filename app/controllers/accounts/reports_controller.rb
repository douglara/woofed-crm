class Accounts::ReportsController < InternalController
  def index
  end

  def summary
    @summaries = ReportBuilder.new(Current.account, params).build(:summary)
  end

  def pipeline_summary
    @pipeline_summary = ReportBuilder.new(Current.account, params).build(:pipeline_summary)
  end
end
