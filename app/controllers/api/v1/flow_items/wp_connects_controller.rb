class Api::V1::FlowItems::WpConnectsController < Api::V1::InternalController
  before_action :set_wp_connect, only: %i[ webhook ]
  before_action :authenticate

  def webhook
    if (params['event'] == 'onmessage')
      FlowItems::ActivitiesKinds::WpConnect::Messages::WebhookWorker.perform_async(params)
    end

    render json: {status: 'ok'}, status: 200
  end

  def set_wp_connect
    @wp_connect = FlowItems::ActivitiesKinds::WpConnect.find(params[:wp_connect_id])
  end

  def authenticate
    token = params[:token]
    if token == @wp_connect.token
      return
    else
      render json: { errors: 'unauthorized' }, status: :unauthorized
    end

    rescue
      render json: { errors: 'unauthorized' }, status: :unauthorized
  end
end
