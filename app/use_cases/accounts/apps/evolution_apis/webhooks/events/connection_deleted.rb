class Accounts::Apps::EvolutionApis::Webhooks::Events::ConnectionDeleted
  def self.call(evolution_api)
    if evolution_api.connected?
      Accounts::Apps::EvolutionApis::Instance::DeleteWorker.perform_in(5.seconds, evolution_api.id)
    end
    Accounts::Apps::EvolutionApis::Instance::Delete.call(evolution_api, true) if evolution_api.connecting?
  end
end
