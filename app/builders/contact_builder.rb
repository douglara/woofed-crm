class ContactBuilder
  def initialize(user, params, search_if_exists = false)
    @params = params
    @user = user
    @search_if_exists = search_if_exists
  end

  def perform
    if @search_if_exists
      @contact = Accounts::Contacts::GetByParams.call(Current.account, contact_params.slice(:phone, :email).to_h)[:ok]
    end
    @contact ||= Contact.new
    @contact.assign_attributes(contact_params)
    @contact
  end

  def contact_params
    @params.permit(:full_name, :phone, :email, :label_list,
                   custom_attributes: {}, additional_attributes: {})
  end
end
