class Accounts::Apps::WppConnects::Webhooks::Messages::Onmessage

  def self.call(wpp_connect, webhook)

    contact = Accounts::Apps::WppConnects::Contacts::FindOrCreate.call(wpp_connect, get_id(webhook['chatId']))[:ok]
  
    message = Accounts::Apps::WppConnects::Messages::FindOrCreate.call(wpp_connect, contact, webhook)

    return message
    
    # if message[:operation] == 'find'
    #   # Refresh message
    # else
    #   return { ok: message }
    # end
  end

  def self.get_id(value)
    value.split('@')[0]
  end
end