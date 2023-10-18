class Accounts::Contacts::EventsController < InternalController
  before_action :set_event, only: %i[ show edit update destroy ]
  before_action :set_contact, only: %i[ show edit update destroy new create ]

  def new
    #@event = current_user.account.events.new(event_params.merge({contact: @contact}))
    @event = EventBuilder.new(current_user, event_params.merge({contact_id: @contact.id})).build
    @options = [ 
      {'name': 'Notas', 'id': 'note'},
      {'name': 'Whatsapp', 'id': 'wpp_connect_message'}
    ]


    if params[:deal_id].present?
      @event.deal_id = params[:deal_id]
      @deal = Deal.find(params[:deal_id])
    end
  end

  def edit
    # @event.broadcast_replace_to @contact,
    #                             partial: 'accounts/contacts/events/forms/event_form' ,
    #                             locals: {contact: @contact, current_user: current_user, event: @event }


  end

  def create
    @deal = Deal.find(params[:deal_id])
    @event = current_user.account.events.new(event_params.merge({contact: @contact}))
    @event.contact = @contact
    @event.deal = @deal
    @event.from_me = true

    if @event.save
      return redirect_to(new_account_contact_event_path(account_id: current_user.account, contact_id: @contact.id, deal_id: @deal.id))
    else
      return render :new, status: :unprocessable_entity
    end
  end
  def destroy
    @event.destroy
    render turbo_stream: [
      turbo_stream.remove(@event)
    ]
  end

  def update
    @deal = current_user.account.deals.find(params[:deal_id])
    @event.update(event_params)
    unless @event.update(event_params)
      render :edit, status: :unprocessable_entity
    end

    # if @event.update(event_params)
    #   render @event
    # else
    #   render :edit, status: :unprocessable_entity
    # end
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
      params.require(:event).permit(:content, :done, :title, :due, :kind, :app_type, :deal_id, :app_id, custom_attributes: {})
    rescue
      {}
    end
end
