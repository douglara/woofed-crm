class Accounts::Settings::CustomAttributesDefinitionsController < InternalController
  before_action :set_custom_attribute_deffinition, only: %i[edit update destroy]

  def index
    @custom_attributes_definitions = current_user.account.custom_attributes_definitions
  end

  def new
    @custom_attributes_definition = current_user.account.custom_attributes_definitions.new
  end

  def create
    @custom_attributes_definition = current_user.account.custom_attributes_definitions.new(custom_attribute_definition_params)
    if @custom_attributes_definition.save
      redirect_to account_custom_attributes_definitions_path(current_user.account),
                  notice: 'Custom attribute was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @custom_attributes_definition.update(custom_attribute_definition_params)
      redirect_to edit_account_custom_attributes_definition_path(current_user.account, @custom_attributes_definition),
                  notice: 'Activity kind was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @custom_attributes_definition.destroy
      flash[:notice] = 'Custom attributes definitions were successfully deleted'
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_custom_attribute_deffinition
    @custom_attributes_definition = current_user.account.custom_attribute_definitions.find(params[:id])
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
