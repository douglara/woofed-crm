class Accounts::Apps::EvolutionApis::Webhooks::Events::ConnectionDeleted
  def self.call(evolution_api)
    if evolution_api.connected?
      Accounts::Apps::EvolutionApis::Instance::DeleteDisconnectedWorker.perform_in(1.seconds, evolution_api.id)
    end
    Accounts::Apps::EvolutionApis::Instance::DeleteDisconnected.new(evolution_api).call if evolution_api.connecting?
  end
end
