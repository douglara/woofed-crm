class Inertia::Accounts::Apps::SalesforcesController < Inertia::InternalController
  # The Salesforce objects offered on the mapping screen, with the Woofed model
  # each one maps onto by default (§6.3 of the integration plan).
  SYNCABLE_OBJECTS = [
    { salesforce_object: 'Account', woofed_model: 'Company' },
    { salesforce_object: 'Contact', woofed_model: 'Contact' },
    { salesforce_object: 'Lead', woofed_model: 'Contact' },
    { salesforce_object: 'Opportunity', woofed_model: 'Deal' },
    { salesforce_object: 'Task', woofed_model: 'Event' },
    { salesforce_object: 'Event', woofed_model: 'Event' }
  ].freeze

  def show
    render inertia: 'Apps/Salesforce/Show', props: {
      connection: connection_props,
      # The connect screen is also the documentation: the user has to register
      # this exact callback and these exact scopes by hand in Salesforce.
      callback_url: apps_salesforces_oauth_callback_url,
      scopes: Apps::Salesforce::Oauth::AuthorizeRequest::SCOPES,
      syncable_objects: SYNCABLE_OBJECTS,
      woofed_models: Apps::Salesforce::ObjectMapping::WOOFED_MODELS,
      woofed_fields: woofed_fields,
      object_mappings: object_mappings_props
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

  def object_mappings_props
    return [] if salesforce.blank?

    salesforce.object_mappings.map do |mapping|
      mapping.slice(:id, :salesforce_object, :woofed_model, :enabled, :field_mappings, :options)
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
