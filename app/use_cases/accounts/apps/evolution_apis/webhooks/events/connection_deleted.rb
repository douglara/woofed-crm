class Accounts::Apps::EvolutionApis::Webhooks::Events::ConnectionDeleted
  def self.call(evolution_api)
    response = update_connection_status(evolution_api)

    { ok: response }
  end

  def self.update_connection_status(evolution_api)
    evolution_api.connection_status = 'inactive'
    evolution_api.save
    evolution_api
  end
end
