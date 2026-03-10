class Inertia::Accounts::Components::ComboboxController < Inertia::InternalController
  MODELS = %w[user contact product pipeline stage deal].freeze

  def search
    return render json: search_label if model_labelable?

    return render json: { error: 'Invalid parameters' }, status: :unprocessable_entity unless MODELS.include?(params[:model])

    model_class = params[:model].classify.constantize
    records = model_class.ransack(params[:q]).result.order(updated_at: :desc).limit(10)

    render json: records.map { |r| { value: r.id.to_s, label: r.label } }
  end

  private

  def search_label
    scope = ActsAsTaggableOn::Tag
    scope = scope.for_context(params[:model]).order(name: :asc).limit(10)
    scope = scope.ransack(params[:q]).result
    scope.map { |tag| { value: tag.id.to_s, label: tag.name } }
  end

  def model_labelable?
    ActsAsTaggableOn::Tag.for_context(params[:model]).exists?
  end
end
