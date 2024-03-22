class Accounts::Apps::EvolutionApis::Message::Import
  def self.call(evolution_api, webhook, content)
    result = create_evolution_api_message_event(evolution_api, webhook, content)
    { ok: result }
  end

  def self.create_evolution_api_message_event(evolution_api, webhook, content)
    contact = find_or_create_contact(evolution_api, webhook)
    import_message(evolution_api, content, contact, webhook)
  end

  def self.find_or_create_contact(evolution_api, webhook)
    phone_number = '+' + webhook['data']['key']['remoteJid'].gsub(/\D/, '')
    contact = Accounts::Contacts::GetByParams.call(evolution_api.account, { phone: phone_number })[:ok]
    if contact.blank?
      contact = Contact.create(full_name: webhook['data']['pushName'], phone: phone_number,
                               account: evolution_api.account)
    end
    contact
  end

  def self.import_message(evolution_api, content, contact, webhook)
    Event.create(
      account: evolution_api.account,
      kind: 'evolution_api_message',
      from_me: webhook['data']['key']['fromMe'],
      contact: contact,
      content: content,
      done: true,
      done_at: webhook['date_time'],
      app: evolution_api,
      additional_attributes: { message_id: webhook['data']['key']['id'] }
    )
  end
end
