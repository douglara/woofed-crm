# frozen_string_literal: true

class Inertia::Accounts::FiltersController < Inertia::InternalController
  # Available resources for filtering
  FILTERABLE_RESOURCES = {
    'contacts' => Contact,
    'deals' => Deal,
    'users' => User
  }.freeze

  # GET /inertia/accounts/:account_id/filters
  # Renders the filter demo page with schema for all resources
  def show
    render inertia: 'v1/Filter/Show', props: {
      resources: available_resources,
      schemas: build_all_schemas,
      accountId: @account.id
    }
  end

  # GET /inertia/accounts/:account_id/filters/schema
  # Returns schema for a specific resource
  def schema
    resource = params[:resource]

    unless FILTERABLE_RESOURCES.key?(resource)
      return render json: { error: 'Invalid resource' }, status: :unprocessable_entity
    end

    model_class = FILTERABLE_RESOURCES[resource]
    fields = ::SchemaBuilder.build(model_class, @account, account_id: @account.id)

    render json: { resource:, fields: }
  end

  private

  def available_resources
    FILTERABLE_RESOURCES.keys.map do |key|
      { value: key, label: key.humanize.pluralize }
    end
  end

  def build_all_schemas
    FILTERABLE_RESOURCES.transform_values do |model_class|
      ::SchemaBuilder.build(model_class, @account, account_id: @account.id)
    end
  end
end
