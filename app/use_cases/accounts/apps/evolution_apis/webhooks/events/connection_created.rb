class Accounts::Apps::EvolutionApis::Webhooks::Events::ConnectionCreated
  def self.call(evolution_api, phone)
    response = update_evolution_api(evolution_api, phone)
    { ok: response }
  end

  def self.update_evolution_api(evolution_api, phone)
    evolution_api.connection_status = 'active'
    evolution_api.phone = "+#{phone}"
    remove_qrcode(evolution_api)
    evolution_api.save
    evolution_api
  end

  def self.remove_qrcode(evolution_api)
    evolution_api.qrcode_info.delete('qrcode')
    evolution_api.qrcode_info.delete('expired_date')
    evolution_api
  end
end
