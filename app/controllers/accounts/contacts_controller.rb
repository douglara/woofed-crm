class Accounts::ContactsController < InternalController
  before_action :set_contact, only: %i[show edit update destroy]

  # GET /contacts or /contacts.json
  def index
    @contacts = current_user.account.contacts
    @pagy, @contacts = pagy(@contacts)
  end

  def select_contact_search
    @contacts = if params[:query].present?
                  current_user.account.contacts.where(
                    'full_name ILIKE :search OR email ILIKE :search OR phone ILIKE :search', search: "%#{params[:query]}%"
                  ).order(updated_at: :desc).limit(5)
                else
                  current_user.account.contacts.order(updated_at: :desc).limit(5)
                end
  end

  def search
    @contacts = current_user.account.contacts.where(
      'full_name ILIKE :search OR email ILIKE :search OR phone ILIKE :search', search: "%#{params[:q]}%"
    ).limit(5).map(&:attributes)

    @results = @contacts.each do |c|
      c[:text] = "#{c['full_name']} - #{c['email']} - #{c['phone']}"
      c
    end

    @results.insert(0, { "id": 0, "text": 'New contact' })

    json = {
      "results": @results
    }
    render json: json
  end

  # GET /contacts/new
  def new
    @contact = Contact.new
  end

  # GET /contacts/1/edit
  def edit; end

  def edit_custom_attributes
    @contact = current_user.account.contacts.find(params[:contact_id])
    @custom_attribute_definitions = current_user.account.custom_attribute_definitions.contact_attribute
  end

  def update_custom_attributes
    @contact = current_user.account.contacts.find(params[:contact_id])
    @contact.custom_attributes[params[:contact][:att_key]] = params[:contact][:att_value]
    if params[:contact][:deal_page_id]
      redirect_to account_deal_path(current_user.account,
                                    params[:contact][:deal_page_id])
    end
    render :edit_custom_attributes, status: :unprocessable_entity unless @contact.save
  end

  # POST /contacts or /contacts.json
  def create
    @contact = current_user.account.contacts.new(contact_params)
    if @contact.save
      respond_to do |format|
        format.html do
          redirect_to account_contact_path(current_user.account, @contact),
                      notice: t('flash_messages.created', model: Contact.model_name.human)
        end
        format.turbo_stream
      end

    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /contacts/1 or /contacts/1.json
  def update
    if @contact.update(contact_params)
      flash[:notice] = 'Contato atualizado com sucesso!'
      if params[:contact][:deal_page_id]
        redirect_to account_deal_path(current_user.account, params[:contact][:deal_page_id])
      else
        render :update, status: :ok
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /contacts/1 or /contacts/1.json
  def destroy
    @contact.destroy
    respond_to do |format|
      format.html do
        redirect_to account_contacts_path(current_user.account),
                    notice: t('flash_messages.deleted', model: Contact.model_name.human)
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
    params.require(:contact).permit(:full_name, :phone, :email, :label_list,
                                    custom_attributes: {})
  end
end
