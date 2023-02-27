class Accounts::Contacts::EventsController < InternalController
  before_action :set_event, only: %i[ show edit update destroy ]
  before_action :set_contact, only: %i[ show edit update destroy new create ]

  # GET /notes
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

  # GET /notes/1/edit
  def edit
  end

  # POST /notes or /notes.json
  def create
    @deal = Deal.find(params[:deal_id])
    @event = current_user.account.events.new(event_params.merge({contact: @contact}))
    @event.contact = @contact
    @event.deal = @deal
    @event.from_me = true

    respond_to do |format|
      if @event.save
        format.html {  redirect_to(new_account_contact_event_path(account_id: current_user.account, contact_id: @contact.id, deal_id: @deal.id), notice: "Note was successfully created.") }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /notes/1 or /notes/1.json
  def update
    respond_to do |format|
      if @note.update(note_params)
        format.html {  redirect_to(deal_path(params[:deal_id]), notice: "Note was successfully updated.") }
        format.json { render :show, status: :ok, location: @note }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
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

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:content, :kind, :app_type, :app_id, custom_attributes: {})
    rescue
      {}
    end
end
