class ContactBuilder
  def initialize(user, params)
    @params = params
    @user = user
  end

  def perform
    @contact = @user.account.contacts.new(@params.permit(:full_name, :phone, :email))
    @contact
  end
end
