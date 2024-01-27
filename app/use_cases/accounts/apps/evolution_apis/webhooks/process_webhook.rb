class Accounts::Apps::EvolutionApis::Webhooks::ProcessWebhook
  def self.call(webhook)
    evolution_api = Apps::EvolutionApi.find_by(instance: webhook['instance'])

    if webhook['event'] == "qrcode.updated"
      Accounts::Apps::EvolutionApis::Webhooks::Events::QrcodeUpdated.call(
        evolution_api, webhook['data']['qrcode']['base64']
      )
    elsif webhook['event'] == "connection.update" && webhook['data']['statusReason'] == 200
      Accounts::Apps::EvolutionApis::Webhooks::Events::ConnectionCreated.call(evolution_api, webhook['sender'].gsub(/\D/, ''))
    end

    { ok: evolution_api }
  end
end
