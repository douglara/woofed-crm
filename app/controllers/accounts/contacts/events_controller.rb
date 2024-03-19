class Accounts::Contacts::EventsController < InternalController
  before_action :set_event, only: %i[show edit update destroy]
  before_action :set_contact, only: %i[show edit update destroy new create]

  def new
    # @event = current_user.account.events.new(event_params.merge({contact: @contact}))
    @event = EventBuilder.new(current_user,
                              event_params.merge({ contact_id: @contact.id, kind: params[:kind],
                                                   deal: params[:deal] })).build

    if params[:deal_id].present?
      @event.deal_id = params[:deal_id]
      @deal = Deal.find(params[:deal_id])
    end
  end

  def edit; end

  def create
    @event = EventBuilder.new(current_user, event_params.merge({ contact: @contact })).build
    if @event.save
      respond_to do |format|
        format.html do
          redirect_to(new_account_contact_event_path(account_id: current_user.account, contact_id: @event.deal.contact.id,
                                                     deal_id: @event.deal.id))
        end
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
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
    @event = Event.find(params[:id])
  end

  def set_contact
    @contact = Contact.find(params[:contact_id])
  end

  # Only allow a list of trusted parameters through.
  def event_params
    params.require(:event).permit(:content, :send_now, :done, :deal_id, :auto_done, :title, :scheduled_at, :from_me, :kind, :app_type,
                                  :app_id, custom_attributes: {}, additional_attributes: {})
  rescue StandardError
    {}
  end
end
