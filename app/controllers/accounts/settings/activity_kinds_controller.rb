class Settings::ActivityKindsController < InternalController
  before_action :set_activity_kind, only: %i[ edit update ]

  def index
    @activity_kinds = ActivityKind.all
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

    def activity_kind_params
      params.require(:activity_kind).permit(settings: {})
    end
end