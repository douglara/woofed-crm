class Query::Filter
  def initialize(rel, params)
    @rel = rel
    @params = params.is_a?(Hash) ? params.dup : params
    @timezone = @params.is_a?(Hash) ? @params.delete('tz') || @params.delete(:tz) : nil
  end

  def call
    apply_filters
  end

  private

  attr_reader :rel, :params, :timezone

  def apply_filters
    if timezone.present? && valid_timezone?(timezone)
      Time.use_zone(timezone) { rel.ransack(params).result }
    else
      rel.ransack(params).result
    end
  end

  def valid_timezone?(tz)
    ActiveSupport::TimeZone[tz].present?
  end
end
