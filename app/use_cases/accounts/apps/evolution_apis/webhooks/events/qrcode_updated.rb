class Accounts::Apps::EvolutionApis::Webhooks::Events::QrcodeUpdated
  def self.call(evolution_api, qrcode)
    evolution_api.update(qrcode: qrcode)
    { ok: evolution_api }
  end
end
