class Accounts::Apps::EvolutionApis::Webhooks::Events::ConnectionDeleted
  def self.call(evolution_api)
    unless evolution_api.disconnected?
      Accounts::Apps::EvolutionApis::Instance::DeleteDisconnected.new(evolution_api).call
    end
  end
end
