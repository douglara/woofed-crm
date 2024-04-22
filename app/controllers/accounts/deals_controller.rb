class Accounts::DealsController < InternalController
  before_action :set_deal, only: %i[show edit update destroy events events_to_do events_done]
  before_action :set_event, only: %i[events_to_do events_done]

  # GET /deals or /deals.json
  def index
    @deals = current_user.account.deals
  end

  # GET /deals/1 or /deals/1.json
  def show; end

  # GET /deals/new
  def new
    @deal = Deal.new
    @stages = current_user.account.stages
    @deal.contact_id = params[:deal][:contact_id]
  end

  def new_select_contact
    @deal = Deal.new
  end

  def add_contact
    @deal = Deal.find(params[:deal_id])
  end

  def commit_add_contact
    @deal = Deal.find(params[:deal_id])
    @new_contact = Contact.find(params['deal']['contact_id'])
    @deal.contacts.push(@new_contact)

    if @deal.save
      redirect_to account_deal_path(current_user.account, @deal)
    else
      render :add_contact, status: :unprocessable_entity
    end
  rescue StandardError
    render :add_contact, status: :unprocessable_entity
  end

  def remove_contact
    @deal = Deal.find(params[:deal_id])
    @contacts_deal = @deal.contacts_deals.find_by_contact_id(params['contact_id'])

    if @contacts_deal.destroy
      redirect_to account_deal_path(current_user.account, @deal)
    else
      render :show, status: :unprocessable_entity
    end
  rescue StandardError
    render :show, status: :unprocessable_entity
  end

  # GET /deals/1/edit
  def edit
    @stages = current_user.account.stages
  end

  def edit_custom_attributes
    @deal = current_user.account.deals.find(params[:deal_id])
    @custom_attribute_definitions = current_user.account.custom_attribute_definitions.deal_attribute
  end

  def update_custom_attributes
    @deal = current_user.account.deals.find(params[:deal_id])
    @deal.custom_attributes[params[:deal][:att_key]] = params[:deal][:att_value]

    if @deal.save
      redirect_to account_deal_path(current_user.account, @deal)
    else
      render :edit_custom_attributes, status: :unprocessable_entity
    end
  end

  # POST /deals or /deals.json
  def create
    @deal = current_user.account.deals.new(deal_params)
    @deal.contact.account = @deal.account

    # @deal = DealBuilder.new(current_user, deal_params).perform

    if @deal.save
      redirect_to account_deal_path(current_user.account, @deal)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create_whatsapp
    @deal = Deal.find(params['deal_id'])
    result = FlowItems::ActivitiesKinds::WpConnect::Messages::Create.call(whatsapp_params.merge({ 'contact_id': @deal.contact.id }))

    respond_to do |format|
      if result.key?(:ok)
        format.html { redirect_to @deal }
        format.json { render :show, status: :created, location: @deal }
      else
        format.html { redirect_to @deal }
        format.json { render json: @deal.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /deals/1 or /deals/1.json
  def update
    if @deal.update(deal_params)
      redirect_to account_deal_path(current_user.account, @deal)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /deals/1 or /deals/1.json
  def destroy
    @deal.destroy
    respond_to do |format|
      format.html { redirect_to root_path, notice: 'Deal was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def events_to_do
    @pagy, @events = pagy(@deal.contact.events.to_do, items: 5)
    @events += [@event] if @event.present?
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def events_done
    @pagy, @events = pagy(@deal.contact.events.done, items: 5)
    @events += [@event] if @event.present?
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_event
    @event = current_user.account.events.find(params[:event_id]) if params[:event_id].present?
  end

  def set_deal
    @deal = current_user.account.deals.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def deal_params
    params.require(:deal).permit(
      :name, :status, :stage_id, :contact_id, :position,
      contact_attributes: %i[id full_name phone email],
      custom_attributes: {}
    )
  end

  def whatsapp_params
    params.require(:flow_item).permit(
      :content, :kind_id
    )
  end
end
