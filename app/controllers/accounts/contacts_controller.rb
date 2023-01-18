class Accounts::ContactsController < InternalController
  before_action :set_contact, only: %i[ show edit update destroy ]

  # GET /contacts or /contacts.json
  def index
    @contacts = Contact.all
    @pagy, @contacts = pagy(@contacts)
  end

  def search
    @contacts = Contact.where('full_name LIKE :search OR email LIKE :search OR phone LIKE :search', search: "%#{params[:q]}%").limit(5).map(&:attributes)
    
    @results = @contacts.each do | c |
      c[:text] = "#{c['full_name']} - #{c['email']}"
      c
    end

    @results.insert(0, {"id": 0, "text": "New contact"})

    json =  {
      "results": @results
    }
    render json: json
  end

  # GET /contacts/new
  def new
    @contact = Contact.new
  end

  # GET /contacts/1/edit
  def edit
  end

  # POST /contacts or /contacts.json
  def create
    @contact = Contact.new(contact_params)

    if @contact.save
      redirect_to account_contact_path(current_user.account, @contact), notice: "Contact was successfully updated."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /contacts/1 or /contacts/1.json
  def update
    respond_to do |format|
      if @contact.update(contact_params)
        redirect_to account_contact_path(current_user.account, @contact), notice: "Contact was successfully updated."
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @contact.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contacts/1 or /contacts/1.json
  def destroy
    @contact.destroy
    respond_to do |format|
      format.html { redirect_to contacts_url, notice: "Contact was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_contact
      @contact = Contact.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def contact_params
      params.require(:contact).permit(:full_name, :phone, :email, custom_attributes: {})
    end
end
