class Api::V1::Contacts::WpConnects::MessagesController < Api::V1::InternalController

  def create
    result = FlowItems::ActivitiesKinds::WpConnect::Messages::Create.call(
      whatsapp_params.merge({'kind_id': params['wp_connect_id']})
    )

    if result.key?(:ok)
      render json: result[:ok], status: :created
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def whatsapp_params
    params.permit(:content, :contact_id)
  end
end
