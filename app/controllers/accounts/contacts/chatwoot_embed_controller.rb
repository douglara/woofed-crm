class Accounts::Contacts::ChatwootEmbedController < InternalController
  layout "embed"
  before_action :set_contact, only: %i[ show ]

  def search
    contact = contact_search

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

    def contact_search()
      if chatwoot_contact['email'].present? && chatwoot_contact['phone_number'].present?
        return current_user.account.contacts.where(
          ":chatwoot_id <@ additional_attributes OR email LIKE :email OR phone LIKE :phone",
          chatwoot_id: { chatwoot_id: "#{chatwoot_contact['id']}" }.to_json,
          email: "#{chatwoot_contact['email']}",
          phone: "#{chatwoot_contact['phone_number']}"
        ).first
      elsif chatwoot_contact['email'].present?
        return current_user.account.contacts.where(
          ":chatwoot_id <@ additional_attributes OR email LIKE :email",
          chatwoot_id: { chatwoot_id: "#{chatwoot_contact['id']}" }.to_json,
          email: "#{chatwoot_contact['email']}"
        ).first
      elsif chatwoot_contact['phone_number'].present?
        return current_user.account.contacts.where(
          ":chatwoot_id <@ additional_attributes OR phone LIKE :phone",
          chatwoot_id: { chatwoot_id: "#{chatwoot_contact['id']}" }.to_json,
          phone: "#{chatwoot_contact['phone_number']}"
        ).first
      else
        return current_user.account.contacts.where(
          ":chatwoot_id <@ additional_attributes",
          chatwoot_id: { chatwoot_id: "#{chatwoot_contact['id']}" }.to_json
        ).first
      end
    end
end
