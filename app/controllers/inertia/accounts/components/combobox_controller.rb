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
    return render json: search_tags if params[:model] == 'acts_as_taggable_on/tag'

    config = MODELS[params[:model]]
    return render json: [] unless config

    records = config[:model].ransack(params[:q]).result.order(updated_at: :desc).limit(10)

    render json: records.map { |r| { value: r.id.to_s, label: r.send(config[:label]) } }
  end

  private

  def search_tags
    scope = ActsAsTaggableOn::Tag
    scope = scope.for_context(params[:context]).order(name: :asc).limit(10) if params[:context].present?
    scope = scope.ransack(params[:q]).result
    scope.map { |tag| { value: tag.id.to_s, label: tag.name } }
  end
end
