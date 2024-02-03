class Apps::EvolutionApisController < ActionController::Base
  skip_before_action :verify_authenticity_token
  def webhooks
    Accounts::Apps::EvolutionApis::Webhooks::ProcessWebhookWorker.perform_async(params.to_json)
    render json: { ok: true }, status: 200
  end
end
