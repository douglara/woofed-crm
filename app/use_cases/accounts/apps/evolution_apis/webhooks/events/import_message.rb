class Accounts::Apps::EvolutionApis::Webhooks::Events::ImportMessage
  def self.call(evolution_api, webhook, content)
    if evolution_api.connected?
      response = Accounts::Apps::EvolutionApis::Message::Import.call(evolution_api, webhook, content)
      { ok: response }
    end
  end
end
