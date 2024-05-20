class Accounts::Settings::CustomAttributesDefinitionsController < InternalController
  before_action :set_custom_attribute_deffinition, only: %i[edit update destroy]

  def index
    @custom_attributes_definitions = current_user.account.custom_attributes_definitions
  end

  def new
    @custom_attribute_definition = current_user.account.custom_attributes_definitions.new
  end

  def create
    @custom_attribute_definition = current_user.account.custom_attributes_definitions.new(custom_attribute_definition_params)
    if @custom_attribute_definition.save
      redirect_to account_custom_attributes_definitions_path(current_user.account),
                  notice: t('flash_messages.created', model: CustomAttributeDefinition.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @custom_attribute_definition.update(custom_attribute_definition_params)
      redirect_to edit_account_custom_attributes_definition_path(current_user.account, @custom_attribute_definition),
                  notice: t('flash_messages.updated', model: CustomAttributeDefinition.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    render :index, status: :unprocessable_entity unless @custom_attribute_definition.destroy
  end

  private

  def set_custom_attribute_deffinition
    @custom_attribute_definition = current_user.account.custom_attribute_definitions.find(params[:id])
  end

  def custom_attribute_definition_params
    params.require(:custom_attribute_definition).permit(
      :attribute_model,
      :attribute_key,
      :attribute_display_name,
      :attribute_description
    )
  end
end
