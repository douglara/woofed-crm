class Accounts::Apps::EvolutionApis::Webhooks::Events::ConnectionCreated
  def self.call(evolution_api, phone)
    response = update_evolution_api(evolution_api, phone)
    { ok: response }
  end

  def self.update_evolution_api(evolution_api, phone)
    evolution_api.connection_status = 'connected'
    evolution_api.phone = "+#{phone}"
    evolution_api.qrcode = ''
    evolution_api.save
    evolution_api
  end
end
