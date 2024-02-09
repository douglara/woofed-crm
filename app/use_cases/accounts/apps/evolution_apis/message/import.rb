class Accounts::Apps::EvolutionApis::Message::Import
  def self.call(evolution_api, webhook, content)
    result = create_evolution_api_message_event(evolution_api, webhook, content)
    { ok: result }
  end

  def self.create_evolution_api_message_event(evolution_api, webhook, content)
    contact = find_contact_by_phone_number(evolution_api, webhook)

    if contact.present?
      import_message(evolution_api, content, contact, webhook)
    else
      contact
    end
  end

  def self.find_contact_by_phone_number(evolution_api, webhook)
    phone_number = '+' + webhook['data']['key']['remoteJid'].gsub(/\D/, '')
    Accounts::Contacts::GetByParams.call(evolution_api.account, { phone: phone_number })[:ok]
  end

  def self.import_message(evolution_api, content, contact, webhook)
    contact.events.create(
      account: evolution_api.account,
      kind: 'evolution_api_message',
      from_me: webhook['data']['key']['fromMe'],
      contact: contact,
      content: content,
      done: true,
      done_at: webhook['date_time'],
      app: evolution_api
    )
  end
end
