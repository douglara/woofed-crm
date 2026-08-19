class Inertia::Accounts::Apps::Salesforces::ObjectMappingsController < Inertia::InternalController
  before_action :set_salesforce

  def create
    mapping = build_mapping

    return redirect_with_alert(mapping.errors.full_messages.to_sentence) unless mapping.save

    redirect_to account_apps_salesforce_path(current_user.account),
                notice: t('flash_messages.updated', model: Apps::Salesforce.model_name.human)
  end

  private

  # One row per Salesforce object, so saving a mapping the user already created
  # updates it instead of failing on the unique index.
  def build_mapping
    mapping = @salesforce.object_mappings.find_or_initialize_by(salesforce_object: mapping_params[:salesforce_object])
    mapping.assign_attributes(mapping_params.except(:options))
    mapping.options = mapping.options.merge(options_params)
    mapping
  end

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
                  field_mappings: %i[salesforce_field woofed_field kind transform],
                  options: %i[stage_field create_placeholder_contact])
  end

  # Merged, never assigned: `options` also holds keys the form does not carry --
  # `stage_map` and `default_stage_id` have no UI yet -- and replacing the column
  # would erase them every time the user saved a mapping from the screen.
  #
  # The checkbox arrives as the string "false", which is truthy in Ruby and is
  # read as a plain value by the loader, so it is cast here rather than there.
  def options_params
    options = mapping_params[:options].to_h
    return options unless options.key?('create_placeholder_contact')

    options.merge('create_placeholder_contact' => ActiveModel::Type::Boolean.new.cast(
      options['create_placeholder_contact']
    ))
  end
end
