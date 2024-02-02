class Api::V1::Accounts::Deals::EventsController < Api::V1::InternalController

  def create
    @deal = @current_user.account.deals.find(params["deal_id"])
    event = @deal.events.new(event_params)
    event.contact = @deal.contact
    event.account = @deal.account
    event.from_me = true

    if event.save
      render json: event, status: :created
    else
      render json: { errors: event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def event_params
    params.permit(:content, :send_now, :done, :auto_done, :done_at,:title, :scheduled_at, :kind, :app_type, :app_id, custom_attributes: {}, additional_attributes: {})
  end
end
