class Accounts::Apps::EvolutionApis::Webhooks::ProcessWebhook
  def self.call(webhook)
    evolution_api = Apps::EvolutionApi.find_by(instance: webhook['instance'])
    if webhook['event'] == 'qrcode.updated'
      Accounts::Apps::EvolutionApis::Webhooks::Events::QrcodeUpdated.call(
        evolution_api, webhook['data']['qrcode']['base64']
      )
    elsif webhook['event'] == 'connection.update'
      if connection_created
        Accounts::Apps::EvolutionApis::Webhooks::Events::ConnectionCreated.call(evolution_api,
                                                                                webhook['sender'].gsub(/\D/, ''))

      elsif connection_deleted
        Accounts::Apps::EvolutionApis::Webhooks::Events::ConnectionDeleted.call(evolution_api)
      end
    end
    { ok: evolution_api }
  end

  def connection_created
    webhook['data']['statusReason'] == '200' && webhook['data']['state'] == 'open'
  end

  def connection_deleted
    webhook['data']['statusReason'] == '401' && webhook['data']['state'] == 'close'
  end
end
