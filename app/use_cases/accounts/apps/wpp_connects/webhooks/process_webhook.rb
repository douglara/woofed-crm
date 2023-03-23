class Accounts::Apps::WppConnects::Webhooks::ProcessWebhook

  def self.call(webhook)
    wpp_connect = Apps::WppConnect.find(webhook['wpp_connect_id'])
    puts("Processa o webhook")
    puts(webhook.inspect)

    if (webhook['event'] == 'status-find')
      Accounts::Apps::WppConnects::Webhooks::Status.call(wpp_connect, webhook)
    elsif (webhook['event'] == 'onparticipantschanged')
      Accounts::Apps::WppConnects::Webhooks::Groups::Onparticipantschanged.call(wpp_connect, webhook)
    elsif (webhook['event'] == 'onmessage')
      Accounts::Apps::WppConnects::Webhooks::Messages::Onmessage.call(wpp_connect, webhook)
    end

    return { ok: wpp_connect }
  end
end