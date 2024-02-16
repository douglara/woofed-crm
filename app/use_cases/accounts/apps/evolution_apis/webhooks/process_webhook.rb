class Accounts::Apps::EvolutionApis::Webhooks::ProcessWebhook
  def self.call(webhook)
    evolution_api = Apps::EvolutionApi.find_by(instance: webhook['instance'])
    if webhook['event'] == 'qrcode.updated'
      Accounts::Apps::EvolutionApis::Webhooks::Events::QrcodeConnectRefresh.call(
        evolution_api, webhook['data']['qrcode']['base64']
      )
    elsif webhook['event'] == 'connection.update'
      if connection_created?(webhook)
        Accounts::Apps::EvolutionApis::Webhooks::Events::ConnectionCreated.call(evolution_api,
                                                                                webhook['sender'].gsub(/\D/, ''))

      elsif connection_deleted?(webhook)
        Accounts::Apps::EvolutionApis::Webhooks::Events::ConnectionDeleted.call(evolution_api)
      end
    elsif webhook['event'] == 'messages.upsert'
      if  webhook['data']['messageType'] == 'extendedTextMessage'
        Accounts::Apps::EvolutionApis::Webhooks::Events::ImportMessage.call(evolution_api, webhook,
                                                                            webhook['data']['message']['extendedTextMessage']['text'])
      elsif webhook['data']['messageType'] == 'conversation'
        Accounts::Apps::EvolutionApis::Webhooks::Events::ImportMessage.call(evolution_api, webhook,
                                                                            webhook['data']['message']['conversation'])
      end
    end
    { ok: evolution_api }
  end

  def self.connection_created?(webhook)
    webhook['data']['statusReason'].to_i == 200 && webhook['data']['state'] == 'open'
  end

  def self.connection_deleted?(webhook)
    (webhook['data']['statusReason'].to_i == 401 || webhook['data']['statusReason'].to_i == 428) && webhook['data']['state'] == 'close'
  end
end
