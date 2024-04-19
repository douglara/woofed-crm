class ContactBuilder
  def initialize(user, params, search_if_exists = false)
    @params = params
    @user = user
    @search_if_exists = search_if_exists
  end

  def perform
    if @search_if_exists
      @contact = Accounts::Contacts::GetByParams.call(@user.account, @params.permit(:phone, :email).to_h)[:ok]
    else
      @contact = @user.account.contacts.new()
    end

    @contact.assign_attributes(@params.permit(:full_name, :phone, :email, additional_attributes: {}))
    @contact
  end
end
