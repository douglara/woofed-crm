class Apps::EvolutionApisController < ActionController::Base
  def webhooks
    Accounts::Apps::EvolutionApis::Webhooks::ProcessWebhookWorker.perform_async(params.to_json)
    render json: { ok: true }, status: 200
  end
end
