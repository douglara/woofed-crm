class Accounts::Apps::EvolutionApis::Webhooks::Events::ConnectionDeleted
  def self.call(evolution_api)
    unless evolution_api.disconnected?
      Accounts::Apps::EvolutionApis::Instance::DeleteWorker.perform_in(5.seconds, evolution_api.id)
    end
  end
end
