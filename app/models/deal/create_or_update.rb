class Deal::CreateOrUpdate
  def initialize(deal, params)
    @deal = deal
    @params = params
  end

  def call
    @deal.assign_attributes(@params)
    return false if @deal.invalid?

    set_lost_at_and_won_at if should_update_lost_at_or_won_at?
    @deal.save!
    @deal
  end

  private

  def should_update_lost_at_or_won_at?
    @deal.status_changed? || @deal.new_record?
  end

  def set_lost_at_and_won_at
    allow_edit = Current.account.deal_allow_edit_lost_at_won_at

    if @deal.won?
      @deal.won_at = Time.current unless allow_edit && @params[:won_at].present?
      @deal.lost_at = nil
      @deal.lost_reason = ''
    elsif @deal.lost?
      @deal.lost_at = Time.current unless allow_edit && @params[:lost_at].present?
      @deal.won_at = nil
    else
      @deal.lost_at = nil
      @deal.won_at = nil
      @deal.lost_reason = ''
    end
  end
end
