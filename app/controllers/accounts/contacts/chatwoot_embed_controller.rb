class Accounts::Contacts::ChatwootEmbedController < InternalController
  layout 'embed'
  before_action :set_contact, only: %i[show]

  def search
    contact = contact_search

    if contact.present?
      redirect_to account_chatwoot_embed_path(current_user.account, contact)
    else
      chatwoot_contact = JSON.parse(params['chatwoot_contact'])
      @contact = current_user.account.contacts.new({
                                                     full_name: chatwoot_contact['name'],
                                                     email: chatwoot_contact['email'],
                                                     phone: chatwoot_contact['phone_number'],
                                                     additional_attributes: { 'chatwoot_id': chatwoot_contact['id'] }
                                                   })
      render :new
    end
  end

  def show; end

  def new
    chatwoot_contact = JSON.parse(params['chatwoot_contact'])
    @contact = current_user.account.contacts.new({
                                                   full_name: chatwoot_contact['name'],
                                                   email: chatwoot_contact['email'],
                                                   phone: chatwoot_contact['phone_number'],
                                                   additional_attributes: { 'chatwoot_id': chatwoot_contact['id'] }
                                                 })
  end

  def create
    @contact = current_user.account.contacts.new(contact_params)

    if @contact.save
      redirect_to account_chatwoot_embed_path(current_user.account, @contact),
                  notice: t('flash_messages.created', model: Contact.model_name.human)
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

  def contact_search
    result = current_user.account.contacts.where(
      "additional_attributes->>'chatwoot_id' = ?", chatwoot_contact['id'].to_s
    ).first
    return result if result.present?

    if chatwoot_contact['email'].present? && chatwoot_contact['phone_number'].present?
      current_user.account.contacts.where(
        'email LIKE :email OR phone LIKE :phone',
        email: chatwoot_contact['email'].to_s,
        phone: chatwoot_contact['phone_number'].to_s
      ).first
    elsif chatwoot_contact['phone_number'].present?
      current_user.account.contacts.where(
        'phone LIKE ?', chatwoot_contact['phone_number'].to_s
      ).first
    elsif chatwoot_contact['email'].present?
      current_user.account.contacts.where(
        'email LIKE ?', chatwoot_contact['email'].to_s
      ).first
    end
  end
end
