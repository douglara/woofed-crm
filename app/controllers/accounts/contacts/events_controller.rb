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
  end

  def create
    @deal = Deal.find(params[:deal_id])
    if event_chatwoot_message?
      create_event_chatwoot_message
    else
      @event = current_user.account.events.new(event_params.merge({contact: @contact}))
      @event.contact = @contact
      @event.deal = @deal
      @event.from_me = true
    end

    if @event.save!
      send_message_to_chatwoot if event_chatwoot_message?
      return redirect_to(new_account_contact_event_path(account_id: current_user.account, contact_id: @contact.id, deal_id: @deal.id))
    else
      return render :new, status: :unprocessable_entity
    end
  end

  def update
    @deal = current_user.account.deals.find(params[:deal_id])
    @event.update(event_params)

    unless @event.update(event_params)
      render :edit, status: :unprocessable_entity
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    def set_contact
      @contact = Contact.find(params[:contact_id])
    end
    def event_chatwoot_message?
      event_params[:kind] == 'chatwoot_message'
    end
    def send_message_to_chatwoot
        Accounts::Apps::Chatwoots::Messages::DeliveryJob.perform_later(@event.id) if event_params[:due].empty?
        Accounts::Apps::Chatwoots::Messages::DeliveryJob.set(wait_until: Time.parse(event_params[:due])).perform_later(@event.id) if !event_params[:due].empty?
    end
    def create_event_chatwoot_message
      @event = current_user.account.events.new(event_params.except(:chatwoot_inbox_id).merge({contact: @contact}))
      @event.deal = @deal
      @event.additional_attributes['chatwoot_inbox_id'] = event_params[:chatwoot_inbox_id]
    end
    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:content, :done, :title, :due, :kind, :app_type, :app_id, :chatwoot_inbox_id, custom_attributes: {})
    rescue
      {}
    end
end
