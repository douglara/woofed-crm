class ContactBuilder
  def initialize(user, params, search_if_exists = false)
    @params = params
    @user = user
    @search_if_exists = search_if_exists
  end

  def perform
    @contact = if @search_if_exists
                 Accounts::Contacts::GetByParams.call(Current.account, @params.permit(:phone, :email).to_h)[:ok]
               else
                 Contact.new
               end

    @contact.assign_attributes(@params.permit(:full_name, :phone, :email, additional_attributes: {}))
    @contact
  end
end
