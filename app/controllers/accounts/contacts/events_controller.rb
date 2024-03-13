class Accounts::Contacts::EventsController < InternalController
  before_action :set_event, only: %i[show edit update destroy]
  before_action :set_contact, only: %i[show edit update destroy new create]

  def new
    # @event = current_user.account.events.new(event_params.merge({contact: @contact}))
    @event = EventBuilder.new(current_user, event_params.merge({ contact_id: @contact.id })).build
    @options = [
      { 'name': 'Notas', 'id': 'note' },
      { 'name': 'Whatsapp', 'id': 'wpp_connect_message' }
    ]

    if params[:deal_id].present?
      @event.deal_id = params[:deal_id]
      @deal = Deal.find(params[:deal_id])
    end
  end

  def edit; end

  def create
    @deal = current_user.account.deals.find(params[:deal_id])
    result = Accounts::Contacts::Events::Create.call(current_user, event_params, params, @contact, @deal)
    has_error = result.any? { |hash| hash.key?(:error) }
    if has_error
      render :new, status: :unprocessable_entity
    else
      redirect_to(new_account_contact_event_path(account_id: current_user.account, contact_id: @contact.id,
                                                 deal_id: @deal.id))
    end
  end

  def destroy
    @event.destroy
  end

  def update
    @deal = current_user.account.deals.find(params[:deal_id])
    @events = @deal.contact.events
    render :edit, status: :unprocessable_entity unless @event.update(event_params)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_event
    @event = current_user.account.events.find(params[:id])
  end

  def set_contact
    @contact = current_user.account.contacts.find(params[:contact_id])
  end

  # Only allow a list of trusted parameters through.
  def event_params
    params.require(:event).permit(:content, :send_now, :done, :auto_done, :title, :scheduled_at, :kind, :app_type,
                                  :app_id, custom_attributes: {}, additional_attributes: {})
  rescue StandardError
    {}
  end
end
