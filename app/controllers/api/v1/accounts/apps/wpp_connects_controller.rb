class Api::V1::Accounts::Apps::WppConnectsController < Api::V1::PublicController
  def webhook
    Accounts::Apps::WppConnects::Webhooks::ProcessWebhook.call(params)

    render json: {'status': 'ok'}, status: :ok 
  end
end