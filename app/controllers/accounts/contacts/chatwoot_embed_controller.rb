class Accounts::Contacts::ChatwootEmbedController < InternalController
  layout "embed"
  before_action :set_contact, only: %i[ show ]

  def search
    contact = current_user.account.contacts.where(
      "? <@ additional_attributes", { chatwoot_id: "#{chatwoot_contact['id']}" }.to_json
    ).first

    contact = current_user.account.contacts.where(
      'email ILIKE :email OR phone ILIKE :phone',
      email: "#{chatwoot_contact['email']}",
      phone: "#{chatwoot_contact['phone_number']}"
    ).first if contact.blank?

    if contact.present?
      redirect_to account_chatwoot_embed_path(current_user.account, contact)
    else
      redirect_to new_account_chatwoot_embed_path(current_user.account, chatwoot_contact: params['chatwoot_contact'])
    end
  end

  def show
  end

  def new
    chatwoot_contact = JSON.parse(params['chatwoot_contact'])
    @contact = current_user.account.contacts.new({
      full_name: chatwoot_contact['name'],
      email: chatwoot_contact['email'],
      phone: chatwoot_contact['phone_number'],
      additional_attributes: {'chatwoot_id': chatwoot_contact['id']}
    })
  end

  def create
    @contact = current_user.account.contacts.new(contact_params)

    if @contact.save
      redirect_to account_chatwoot_embed_path(current_user.account, @contact), notice: "Contact was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_contact
      @contact = Contact.find(params[:id])
    end

    def contact_params
      params.require(:contact).permit(:full_name, :phone, :email, additional_attributes: {})
    end

    def chatwoot_contact
      @chatwoot_contact ||= JSON.parse(params['chatwoot_contact'])
    end
end
