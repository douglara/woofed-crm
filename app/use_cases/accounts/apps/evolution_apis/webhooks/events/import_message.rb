class Accounts::Apps::EvolutionApis::Webhooks::Events::ImportMessage
  def self.call(evolution_api, webhook, content)
    if evolution_api.connected?
      response = Accounts::Apps::EvolutionApis::Message::Import.new(evolution_api, webhook, content).call
      { ok: response }
    end
  end
end
