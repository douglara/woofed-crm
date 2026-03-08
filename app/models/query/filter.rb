class Query::Filter
  def initialize(rel, params)
    @rel = rel
    @params = params
  end

  def call
    apply_filters
  end

  private

  attr_reader :rel, :params

  def apply_filters
    rel.ransack(params).result
  end
end
