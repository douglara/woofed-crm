class Accounts::Apps::EvolutionApis::Webhooks::Events::QrcodeUpdated
  def self.call(evolution_api, qrcode)
    evolution_api.update(additional_attributes: { 'qrcode': qrcode,
                                                  'expiration_date': (Time.current + 50.seconds).to_s })
    { ok: evolution_api }
  end
end
