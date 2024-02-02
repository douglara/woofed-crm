class Accounts::Apps::EvolutionApis::Webhooks::Events::ConnectionDeleted
  def self.call(evolution_api)
    unless evolution_api.disconnected?
      response = Accounts::Apps::EvolutionApis::Instance::Delete.call(evolution_api)
      { ok: response }
    end
  end
end
