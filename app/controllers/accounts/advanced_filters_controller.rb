class Accounts::AdvancedFiltersController < InternalController
  MODELS = %w[deal contact user product].freeze

  def show
    return render plain: 'Invalid model', status: :unprocessable_entity unless MODELS.include?(params[:model])

    @model_class = params[:model].classify.constantize
    @redirect_url = params[:redirect_url]
    @fields = ModelSchemaBuilder.build(@model_class)
    @initial_filters = params[:filter] || {}
  end
end
