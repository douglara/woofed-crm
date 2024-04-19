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
    if group_message?(webhook)
      find_or_create_group_contact(evolution_api, webhook)
    else
      find_or_create_person_contact(evolution_api, webhook)
    end
  end

  def self.find_or_create_person_contact(evolution_api, webhook)
    phone_number = '+' + webhook['data']['key']['remoteJid'].gsub(/\D/, '')
    contact = Accounts::Contacts::GetByParams.call(evolution_api.account, { phone: phone_number })[:ok]
    if contact.blank?
      contact = Contact.create(full_name: webhook['data']['pushName'], phone: phone_number,
                               account: evolution_api.account)
    end
    contact
  end

  def self.find_or_create_group_contact(evolution_api, webhook)
    group_id = webhook['data']['key']['remoteJid']
    group_details = group_details(evolution_api, group_id)
    contact_params = {
      full_name: "#{group_details[:group_name]} - Grupo",
      additional_attributes: group_details
    }

    contact = evolution_api.account.contacts.where('additional_attributes @> ?', { group_id: group_id }.to_json).first
    if contact.present?
      contact.full_name = contact_params[:full_name]
      contact.additional_attributes = contact.additional_attributes.merge(contact_params[:additional_attributes])
    else
      contact = ContactBuilder.new(
        evolution_api.account.users.first,
        ActionController::Parameters.new(contact_params)
      ).perform
    end

    contact.save!
    contact
  end

  def self.group_details(evolution_api, group_id)
    request = Faraday.get(
      "#{evolution_api.endpoint_url}/group/findGroupInfos/#{evolution_api.instance}?groupJid=#{group_id}",
      {},
      evolution_api.request_instance_headers
    )
    request_body = JSON.parse(request.body)

    { group_id: group_id,
      group_name: request_body['subject'],
      group_owner_id: request_body['subjectOwner'] }
  end

  def self.group_message?(webhook)
    webhook['data']['key']['remoteJid'].gsub(/\D/, '').size > 15
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
