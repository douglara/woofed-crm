class Accounts::Settings::CustomAttributesDefinitionsController < InternalController
  before_action :set_activity_kind, only: %i[ edit update ]

  def index
    @custom_attributes_definitions = current_user.account.custom_attributes_definitions
  end

  def new
    @custom_attributes_definition = current_user.account.custom_attributes_definitions.new
  end

  def create
    @custom_attributes_definition = current_user.account.custom_attributes_definitions.new(custom_attributes_definition_params)

    respond_to do |format|
      if @custom_attributes_definition.save
        format.html { redirect_to account_custom_attributes_definitions_path(current_user.account), notice: "Custom attribute was successfully created." }
        format.json { render :show, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @custom_attributes_definition.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @activity_kind.update(activity_kind_params)
        format.html { redirect_to edit_settings_activity_kind_path(@activity_kind), notice: "Activity kind was successfully updated." }
        format.json { render :edit, status: :ok, location: @contact }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @activity_kind.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def set_activity_kind
      @activity_kind = ActivityKind.find(params[:id])
    end

    def custom_attributes_definition_params
      params.require(:custom_attribute_definition).permit(
        :attribute_model,
        :attribute_key,
        :attribute_display_name,
        :attribute_description)
    end
end