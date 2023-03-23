class Accounts::Apps::WppConnects::Webhooks::Status

  def self.call(wpp_connect, webhook)
    if (webhook['status'] == 'inChat')
      wpp_connect.update(status: 'active', active: true)
      Accounts::Apps::WppConnects::Sync::FullSyncWorker.perform_in(1.minutes, wpp_connect.id)
    end

    return { ok: wpp_connect }
  end
end