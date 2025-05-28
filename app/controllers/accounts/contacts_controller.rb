class Accounts::ContactsController < InternalController
  before_action :set_contact, only: %i[show edit update destroy chatwoot_conversation_link hovercard_preview]

  # GET /contacts or /contacts.json
  def index
    @contacts = if params[:query].present?
                  Contact.where(
                    'full_name ILIKE :search OR email ILIKE :search OR phone ILIKE :search', search: "%#{params[:query]}%"
                  ).order(updated_at: :desc)
                else
                  Contact.all.order(created_at: :desc)
                end

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
    render json:
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
    if params[:contact][:att_key].present?
      @contact.custom_attributes[params[:contact][:att_key]] = params[:contact][:att_value]
    end

    if @contact.update(contact_params)
      flash[:notice] = t('flash_messages.updated', model: Contact.model_name.human)
      respond_to do |format|
        format.html { redirect_to account_contact_path(current_user.account, @contact) }
        format.turbo_stream
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

  def chatwoot_conversation_link
    @chatwoot_conversation_link = Contact::Integrations::Chatwoot::GenerateConversationLink.new(@contact).call[:ok]
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed
    @connection_error = true
  end

  def hovercard_preview
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
