class Accounts::Apps::WppConnects::Messages::FindOrCreate

  def self.call(wpp_connect, contact, message_event)
    wp_id = message_event['id']
    message_find = Event.find_by('app_id = ? and additional_attributes @> ?', wpp_connect.id, {"source_id"=> wp_id}.to_json, )

    if message_find != nil
      return { ok: message_find }
    else
      return { ok: import_message(wpp_connect, contact, message_event) }
    end
  end

  def self.import_message(wpp_connect, contact, message_event)
  
    return Event.create(
      contact: contact,
      app: wpp_connect,
      account: wpp_connect.account,
      kind: 'wpp_connect_message',
      from_me: false,
      done_at:  Time.at(message_event['t']),
      content: message_event['content'],
      additional_attributes: {'source_id': message_event['id'] }
    )
  end
end