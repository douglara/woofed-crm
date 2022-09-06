class Accounts::Deals::ActivitiesController < InternalController
  before_action :set_activity, only: %i[ show edit update destroy ]
  before_action :set_deal, only: %i[ create edit update ]

  # GET /activities/1/edit
  def edit
  end

  # POST /activities or /activities.json
  def create
    @activity = Activity.new(activity_params)
    @flow_item = FlowItem.new(deal_id: @deal.id, contact_id: @deal.contact.id, record: @activity)

    respond_to do |format|
      if @activity.save && @flow_item.save
        format.html {  redirect_to(deal_path(@deal), notice: "Activity was successfully created.") }
        format.json { render :show, status: :created, location: @activity }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /activities/1 or /activities/1.json
  def update
    respond_to do |format|
      if @activity.update(activity_params)
        format.html {  redirect_to(deal_path(@deal), notice: "Activity was successfully updated.") }
        format.json { render :show, status: :ok, location: @activity }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /activities/1 or /activities/1.json
  def destroy
    @activity.destroy
    respond_to do |format|
      format.html { redirect_to activities_url, notice: "Activity was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_activity
      @activity = Activity.find(params[:id])
    end

    def set_deal
      @deal = Deal.find(params[:deal_id])
    end

    # Only allow a list of trusted parameters through.
    def activity_params
      params.require(:activity).permit(:name, :activity_kind_id, :due, :done, :content)
    end
end
