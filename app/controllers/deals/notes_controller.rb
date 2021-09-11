class Deals::NotesController < InternalController
  before_action :set_note, :set_deal, only: %i[ show edit update destroy ]

  # GET /notes/1/edit
  def edit
  end

  # POST /notes or /notes.json
  def create
    @deal = Deal.find(params[:deal_id])
    @note = Note.new(note_params)
    @flow_item = FlowItem.new(deal_id: @deal.id, contact_id: @deal.contact.id, record: @note)

    respond_to do |format|
      if @note.save && @flow_item.save
        format.html {  redirect_to(deal_path(params[:deal_id]), notice: "Note was successfully created.") }
        #format.json { render :show, status: :created, location: @note }
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
    def set_note
      @note = Note.find(params[:id])
    end

    def set_deal
      @deal = Deal.find(params[:deal_id])
    end

    # Only allow a list of trusted parameters through.
    def note_params
      params.require(:note).permit(:content, :flow_item_id)
    end
end
