class Apps::EvolutionApi::Webhooks::Events::ConnectionDeleted
  def self.call(evolution_api)
    if evolution_api.connected?
      Apps::EvolutionApi::Instance::DeleteDisconnectedWorker.perform_in(1.seconds, evolution_api.id)
    end
    Apps::EvolutionApi::Instance::DeleteDisconnected.new(evolution_api).call if evolution_api.connecting?
  end
end
