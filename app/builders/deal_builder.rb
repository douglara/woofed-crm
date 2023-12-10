class DealBuilder
  def initialize(user, params)
    @params = params
    @user = user
  end

  def build
    @deal = @user.account.deals.new(deal_params(@params))
    build_contact
    @deal
  end

  def perform
    build
    @deal
  end

  private

  def build_contact
    @contact = ContactBuilder.new(@user, @params[:contact_attributes]).perform
    @deal.contact = @contact
  end

  def deal_params(params)
    params.permit(
      :name, :status, :stage_id, :contact_id,
      contact_attributes: [ :id, :full_name, :phone, :email, :account_id ],
      custom_attributes: {}
    )
  end
end
