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
    config = MODELS[params[:model]]
    return render json: [] unless config

    records = config[:model].ransack(params[:q]).result.order(updated_at: :desc).limit(10)

    render json: records.map { |r| { value: r.id.to_s, label: r.send(config[:label]) } }
  end
end
