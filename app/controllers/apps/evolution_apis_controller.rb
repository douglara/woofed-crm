class Apps::EvolutionApisController < Api::V1::PublicController
  def webhooks
    Accounts::Apps::EvolutionApis::Webhooks::ProcessWebhookWorker.perform_async(params.to_json)
    render json: { ok: true }, status: 200
  end
end
