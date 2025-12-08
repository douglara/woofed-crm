class DealBuilder
  include DealConcern

  def initialize(user, params)
    @params = params
    @user = user
  end

  def build
    @deal = Deal.new(deal_params.merge(created_by_id: user.id))
    attach_contact_if_needed
    assign_user_to_deal
    deal
  end

  def perform = build

  private

  attr_reader :user, :params, :deal

  def attach_contact_if_needed
    return if deal_params[:contact_id].present? || deal_params[:contact_attributes].blank?

    contact = ContactBuilder.new(user, deal_params[:contact_attributes], true).perform
    deal.contact = contact
  end

  def assign_user_to_deal
    deal.deal_assignees.build(user:)
  end

  def deal_params
    params.permit(*permitted_deal_params)
  end
end
