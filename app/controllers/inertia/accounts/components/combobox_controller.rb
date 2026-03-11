class Inertia::Accounts::Components::ComboboxController < Inertia::InternalController
  MODELS = {
    'user' => { model: User, label: :full_name },
    'contact' => { model: Contact, label: :full_name },
    'product' => { model: Product, label: :name },
    'pipeline' => { model: Pipeline, label: :name },
    'stage' => { model: Stage, label: :name },
    'deal' => { model: Deal, label: :name }
  }.freeze

  def search
    return render json: search_label if model_labelable?

    return render json: { error: 'Invalid parameters' }, status: :unprocessable_entity unless MODELS.include?(params[:model])

    config = MODELS[params[:model]]
    records = Query::Filter.new(config[:model], params[:q]).call.order(updated_at: :desc).limit(10)
    render json: records.map { |r| { value: r.id.to_s, label: r.send(config[:label]) } }
  end

  private

  def search_label
    scope = ActsAsTaggableOn::Tag
    scope = scope.for_context(params[:model]).order(name: :asc).limit(10)
    records = Query::Filter.new(scope, params[:q]).call
    records.map { |tag| { value: tag.id.to_s, label: tag.name } }
  end

  def model_labelable?
    ActsAsTaggableOn::Tag.for_context(params[:model]).exists?
  end
end
