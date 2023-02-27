class Accounts::Contacts::Events::Apps::WppConnects::MessagesController < InternalController
  before_action :set_event, only: %i[ show edit update destroy ]
  before_action :set_contact, only: %i[ show edit update destroy new create ]

  # GET /notes
  def new
    @event = Event.new(contact: @contact)
    @wpp_connects = current_user.account.apps_wpp_connects.actives
  end

  # GET /notes/1/edit
  def edit
  end

  # POST /notes or /notes.json
  def create
    @deal = Deal.find(params[:deal_id])
    @event = Event.new(event_params)
    @event.account = current_user.account
    @event.contact = @contact
    @event.deal = @deal
    @event.event_kind = EventKind.find_by_key('note')
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
      params.require(:event).permit(:content)
    end
end
