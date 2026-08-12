class Inertia::Accounts::Apps::Salesforces::ObjectMappingsController < Inertia::InternalController
  before_action :set_salesforce

  # One row per Salesforce object, so saving a mapping the user already created
  # updates it instead of failing on the unique index.
  def create
    mapping = @salesforce.object_mappings.find_or_initialize_by(salesforce_object: mapping_params[:salesforce_object])
    mapping.assign_attributes(mapping_params)

    return redirect_with_alert(mapping.errors.full_messages.to_sentence) unless mapping.save

    redirect_to account_apps_salesforce_path(current_user.account),
                notice: t('flash_messages.updated', model: Apps::Salesforce.model_name.human)
  end

  private

  def set_salesforce
    @salesforce = Apps::Salesforce.first

    redirect_with_alert(t('apps.salesforce.missing_connection')) if @salesforce.blank?
  end

  def redirect_with_alert(message)
    redirect_to account_apps_salesforce_path(current_user.account), alert: message
  end

  def mapping_params
    params.require(:object_mapping)
          .permit(:salesforce_object, :woofed_model, :enabled,
                  field_mappings: %i[salesforce_field woofed_field kind transform])
  end
end
