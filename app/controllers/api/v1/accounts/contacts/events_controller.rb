class Api::V1::Accounts::Contacts::EventsController < Api::V1::InternalController
  def create
    @contact = Contact.find(params['contact_id'])
    event = @contact.events.new(event_params)
    event.from_me = true

    if event.save
      render json: event, status: :created
    else
      render json: { errors: event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def event_params
    params.permit(:content, :send_now, :done, :auto_done, :done_at, :title, :scheduled_at, :kind, :app_type, :app_id,
                  :deal_id, custom_attributes: {}, additional_attributes: {})
  end
end
