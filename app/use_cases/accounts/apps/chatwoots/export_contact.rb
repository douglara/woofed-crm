class Accounts::Apps::Chatwoots::ExportContact
  def self.call(chatwoot, contact)
    create_or_update_contact(chatwoot, contact)
  end

  def self.create_or_update_contact(chatwoot, contact)
    contact_chatwoot_id = contact['additional_attributes']['chatwoot_id']

    if contact_chatwoot_id.present?
      update_contact(chatwoot, contact)
    else
      create_contact(chatwoot, contact)
    end
  end

  def self.update_contact(chatwoot, contact)
    request = Faraday.put(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{contact.additional_attributes['chatwoot_id']}",
      build_body(contact),
      chatwoot.request_headers
    )
    if request.status == 200
      export_contact_tags(chatwoot, contact)
      { ok: contact }
    else
      { error: request.body }
    end
  end

  def self.export_contact_tags(chatwoot, contact)
    request = Faraday.post(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{contact.additional_attributes['chatwoot_id']}/labels",
      { labels: contact.label_list }.to_json,
      chatwoot.request_headers
    )
    JSON.parse(request.body)['payload']
  end

  def self.create_contact(chatwoot, contact)
    request = Faraday.post(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts",
      build_body(contact),
      chatwoot.request_headers
    )
    response_body = JSON.parse(request.body)
    if response_body['message'] == 'Email has already been taken' && request.status == 422
      search_chatwoot_contact = Accounts::Apps::Chatwoots::SearchContact.call(chatwoot, contact['email'])
      update_contact_chatwoot_id_and_identifier(contact, search_chatwoot_contact['id'],
                                                search_chatwoot_contact['identifier'])
      { ok: contact }
    elsif response_body['message'] == 'Phone number has already been taken' && request.status == 422
      search_chatwoot_contact = Accounts::Apps::Chatwoots::SearchContact.call(chatwoot, contact['phone'])
      update_contact_chatwoot_id_and_identifier(contact, search_chatwoot_contact['id'],
                                                search_chatwoot_contact['identifier'])
      { ok: contact }
    elsif request.status == 200
      update_contact_chatwoot_id_and_identifier(contact, response_body['payload']['contact']['id'],
                                                response_body['payload']['contact']['identifier'])
      export_contact_tags(chatwoot, contact)
      { ok: contact }
    else
      Rails.logger.error(
        'Error when export contact to chatwoot,' +
        "Chatwoot Apps: #{chatwoot.inspect}," +
        "Chatwoot request: #{request.inspect}," +
        "Chatwoot response: #{request.body}"
      )
      { error: request.body }
    end
  end

  def self.update_contact_chatwoot_id_and_identifier(contact, chatwoot_id, chatwoot_identifier)
    contact.update(additional_attributes: contact['additional_attributes'].merge({ chatwoot_id: chatwoot_id,
                                                                                   chatwoot_identifier: chatwoot_identifier }))
  end

  def self.build_body(contact)
    {
      "name": contact['full_name'],
      "email": contact['email'],
      "phone_number": contact['phone'],
      "custom_attributes": contact['custom_attributes']
    }.to_json
  end
end
