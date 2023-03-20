class DealBuilder

  def initialize(user, params)
    @params = params
    @user = user
  end

  def build
    @deal = @user.account.deals.new(deal_params(@params))
    fill_contact_account
    @deal
  end

  def perform
    build
    @deal.save!
    @deal
  end

  private
  
  def fill_contacts
    @params[:contacts] = @params[:contacts].map { | c |
      c.merge({account_id: @user.account_id})
    } if @params[:contacts].present?




    if @deal.contact_main.blank?
      @deal.contact_main = self.contact
    end

    if self.contact.blank?
      self.contact = self.contacts.first
    end

  end

  # def deal_params
  #   # @params[:contacts] = @params[:contacts].map { | c |
  #   #   c.merge({account_id: @user.account_id})
  #   # }
  #   @params
  # end

  def fill_contact_account()
    @deal.contact.account = @user.account
  end

  def deal_params(params)
    params.permit(
      :name, :status, :stage_id, :contact_id,
      contact_attributes: [ :id, :full_name, :phone, :email, :account_id ],
      custom_attributes: {}
    )
  end
end