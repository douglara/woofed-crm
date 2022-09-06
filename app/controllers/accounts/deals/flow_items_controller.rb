class Accounts::Deals::FlowItemsController < InternalController
  before_action :set_flow_item, :set_deal, only: %i[ destroy ]

  # DELETE /activities/1 or /activities/1.json
  def destroy
    @flow_item.destroy
    respond_to do |format|
      format.html { redirect_to(deal_path(@deal), notice: "Item was successfully destroyed.") }
      format.json { head :no_content }
    end
  end

  private
    def set_flow_item
      @flow_item = FlowItem.find(params[:id])
    end

    def set_deal
      @deal = Deal.find(params[:deal_id])
    end
end
