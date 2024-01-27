class Accounts::Apps::EvolutionApis::Webhooks::Events::QrcodeUpdated
  def self.call(evolution_api, webhook)
    evolution_api.update(additional_attributes: { 'qrcode': webhook['qrcode']['base64'],
                                                  'expiration_date': (Time.current + 50.seconds).to_s })
    { ok: evolution_api }
  end
end
