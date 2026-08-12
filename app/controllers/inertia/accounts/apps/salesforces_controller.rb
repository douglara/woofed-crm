class Inertia::Accounts::Apps::SalesforcesController < Inertia::InternalController
  # The Woofed model each standard object maps onto by default (§6.3 of the
  # integration plan). Only a suggestion: any object, custom ones included, can
  # be pointed at any of the four models the sync writes to -- a Company may come
  # from Account in one org and from School__c in another.
  SUGGESTED_MODELS = {
    'Account' => 'Company',
    'Contact' => 'Contact',
    'Lead' => 'Contact',
    'Opportunity' => 'Deal',
    'Task' => 'Event',
    'Event' => 'Event'
  }.freeze

  def show
    render inertia: 'Apps/Salesforce/Show', props: {
      connection: connection_props,
      # The connect screen is also the documentation: the user has to register
      # this exact callback and these exact scopes by hand in Salesforce.
      callback_url: apps_salesforces_oauth_callback_url,
      scopes: Apps::Salesforce::Oauth::AuthorizeRequest::SCOPES,
      syncable_objects: syncable_objects,
      woofed_models: Apps::Salesforce::ObjectMapping::WOOFED_MODELS,
      woofed_fields: woofed_fields,
      object_mappings: object_mappings_props,
      sync_runs: sync_runs_props
    }
  end

  def create
    salesforce = Apps::Salesforce.first || Apps::Salesforce.new
    salesforce.assign_attributes(salesforce_params)

    return redirect_with_alert(salesforce.errors.full_messages.to_sentence) unless salesforce.save

    authorization = Apps::Salesforce::Oauth::AuthorizeRequest.new(salesforce).call
    # The verifier proves, at callback time, that this install started the flow.
    # It never leaves Woofed.
    session[:salesforce_oauth] = {
      'state' => authorization[:state],
      'code_verifier' => authorization[:code_verifier]
    }

    redirect_to authorization[:url], allow_other_host: true
  end

  def destroy
    Apps::Salesforce.first&.destroy

    redirect_to account_apps_salesforce_path(current_user.account), notice: t('apps.salesforce.disconnected')
  end

  # The initial load, one run per enabled mapping. Nothing is downloaded before
  # the user asks for it: connecting an org imports nothing on its own.
  def sync
    result = Apps::Salesforce::Backfill::Start.new(salesforce).call

    return redirect_with_alert(result[:error]) if result.key?(:error)

    redirect_to account_apps_salesforce_path(current_user.account), notice: t('apps.salesforce.backfill.started')
  end

  # Feeds the field pickers. The describe payload is cached, so opening the same
  # object twice costs one call to the org.
  def describe
    return render json: { error: t('apps.salesforce.missing_connection') }, status: :not_found if salesforce.blank?

    result = Apps::Salesforce::Api::Sobject::Describe.call(salesforce, params[:salesforce_object])
    return render json: { error: result[:error] }, status: :unprocessable_entity if result.key?(:error)

    render json: { fields: describe_fields(result[:ok]) }
  end

  private

  def salesforce
    @salesforce ||= Apps::Salesforce.first
  end

  def connection_props
    return nil if salesforce.blank?

    salesforce.slice(:id, :name, :status, :environment, :instance_url, :organization_id, :token_expires_at)
              .merge(connected: salesforce.connected?)
  end

  # Read from the org so custom objects can be mapped too. Before a connection
  # exists there is nothing to ask, and the standard objects stand in.
  def syncable_objects
    return suggested_objects if salesforce.blank?

    result = Apps::Salesforce::Api::Sobject::List.call(salesforce)
    return suggested_objects if result.key?(:error)

    result[:ok].map do |sobject|
      {
        salesforce_object: sobject['name'],
        label: sobject['label'],
        custom: sobject['custom'],
        woofed_model: SUGGESTED_MODELS[sobject['name']]
      }
    end
  end

  def suggested_objects
    SUGGESTED_MODELS.map do |salesforce_object, woofed_model|
      { salesforce_object: salesforce_object, label: salesforce_object, custom: false, woofed_model: woofed_model }
    end
  end

  def object_mappings_props
    return [] if salesforce.blank?

    salesforce.object_mappings.map do |mapping|
      mapping.slice(:id, :salesforce_object, :woofed_model, :enabled, :field_mappings, :options)
    end
  end

  # The latest run per object: what the sync section shows as progress.
  def sync_runs_props
    return [] if salesforce.blank?

    salesforce.sync_runs.order(created_at: :desc).group_by(&:salesforce_object).map do |_object, runs|
      runs.first.slice(:id, :salesforce_object, :kind, :status, :records_downloaded, :error, :finished_at)
    end
  end

  def woofed_fields
    Apps::Salesforce::ObjectMapping::WOOFED_MODELS.index_with do |model|
      Apps::Salesforce::WoofedFields.call(model)
    end
  end

  # Only what a picker needs: the payload itself is hundreds of KB.
  def describe_fields(payload)
    payload.fetch('fields', []).map do |field|
      { name: field['name'], label: field['label'], type: field['type'], custom: field['custom'] }
    end
  end

  def redirect_with_alert(message)
    redirect_to account_apps_salesforce_path(current_user.account), alert: message
  end

  def salesforce_params
    params.require(:apps_salesforce).permit(:name, :environment, :client_id, :client_secret)
  end
end
