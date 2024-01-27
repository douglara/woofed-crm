class Accounts::Apps::EvolutionApis::Webhooks::ProcessWebhook
  def self.call(webhook)
    evolution_api = Apps::EvolutionApi.find_by(instance: webhook['instance']['instanceName'])

    if webhook['webhook']['events'].include?('QRCODE_UPDATED')
      Accounts::Apps::EvolutionApis::Webhooks::Events::QrcodeUpdated.call(
        evolution_api, webhook['qrcode']['base64']
      )
    end

    { ok: evolution_api }
  end
end
