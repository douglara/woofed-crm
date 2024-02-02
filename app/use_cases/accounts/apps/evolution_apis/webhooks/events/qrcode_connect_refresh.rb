class Accounts::Apps::EvolutionApis::Webhooks::Events::QrcodeConnectRefresh
  def self.call(evolution_api, qrcode)
    if evolution_api.connecting?
      evolution_api.update(qrcode: qrcode)
      { ok: evolution_api }
    end
  end
end
