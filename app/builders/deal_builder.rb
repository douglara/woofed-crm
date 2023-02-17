class DealBuilder

  def initialize(user, params)
    @params = params
    @user = user
  end

  def build
    @deal = @user.account.deals.new(deal_params)
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

  def deal_params
    # @params[:contacts] = @params[:contacts].map { | c |
    #   c.merge({account_id: @user.account_id})
    # }
    @params
  end
end