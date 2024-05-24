class Accounts::AppsController < InternalController
  before_action :set_contact, only: %i[show edit update destroy]

  # GET /contacts or /contacts.json
  def index
    @apps = current_user.account.apps
    @pagy, @apps = pagy(@apps)
  end

  # GET /contacts/new
  def new
    @contact = Contact.new
  end

  # GET /contacts/1/edit
  def edit; end

  # POST /contacts or /contacts.json
  def create
    @contact = current_user.account.contacts.new(contact_params)

    if @contact.save
      redirect_to account_contact_path(current_user.account, @contact),
                  notice: t('flash_messages.created', model: Contact.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /contacts/1 or /contacts/1.json
  def update
    respond_to do |format|
      if @contact.update(contact_params)
        redirect_to account_contact_path(current_user.account, @contact),
                    notice: t('flash_messages.updated', model: Contact.model_name.human)
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
      format.html do
        redirect_to contacts_url, notice: t('flash_messages.deleted', model: Contact.model_name.human)
      end
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
