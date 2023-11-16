class Accounts::Apps::Chatwoots::Webhooks::ImportContact

  def self.call(chatwoot, contact_id)
    contact = get_or_import_contact(chatwoot, contact_id)
    return { ok: contact }
  end

  def self.get_or_import_contact(chatwoot, contact_id)
    contact = chatwoot.account.contacts.where(
      "additional_attributes->>'chatwoot_id' = ?", "#{contact_id}"
    ).first
    contact_att = get_contact(chatwoot, contact_id)
    return 'Contact not found' if contact_att == false

    if contact.present?
      contact = update_contact(chatwoot, contact_id, contact, contact_att)
    else
      contact = import_contact(chatwoot, contact_id, contact_att)
    end

    contact = import_contact_tags(chatwoot, contact)
    contact = import_contact_converstions_tags(chatwoot, contact)
    contact.save
    return contact
  end

  def self.get_contact(chatwoot, contact_id)
    contact_response = Faraday.get(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{contact_id}",
      {},
      chatwoot.request_headers
    )
    if contact_response.status == 200
      body = JSON.parse(contact_response.body)
      return body['payload']
    elsif contact_response.status == 404
      Rails.logger.info "Contact id #{contact_id} not found in Chatwoot App #{chatwoot.id}"
      return false
    else
      Rails.logger.info "contact_response: #{contact_response.inspect}"
      Rails.logger.info "contact_response body: #{contact_response.body}"
      raise "ErrorChatwootGetContact"
    end
  end

  def self.import_contact_converstions_tags(chatwoot, contact)
    contact_response = Faraday.get(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{contact.additional_attributes['chatwoot_id']}/conversations",
      {},
      chatwoot.request_headers
    )

    body = JSON.parse(contact_response.body)
    conversations_tags = body['payload'].map { | c | c['labels'] }.flatten.uniq
    contact.assign_attributes({ chatwoot_conversations_label_list: conversations_tags})
    return contact
  end

  def self.import_contact_tags(chatwoot, contact)
    contact_response = Faraday.get(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{contact.additional_attributes['chatwoot_id']}/labels",
      {},
      chatwoot.request_headers
    )
    body = JSON.parse(contact_response.body)
    contact.assign_attributes({label_list: body['payload']})
    return contact
  end

  def self.import_contact(chatwoot, contact_id, contact_att)
    contact = chatwoot.account.contacts.new
    contact = build_contact_att(contact, contact_id, contact_att)
    contact
  end


  def self.update_contact(chatwoot, contact_id, contact, contact_att)
    contact = build_contact_att(contact, contact_id, contact_att)
    contact
  end

  def self.build_contact_att(contact, contact_id, body)
    contact.assign_attributes({
      full_name: body['name'],
      email: "#{body['email']}",
      phone: "#{body['phone_number']}",
    })

    contact.additional_attributes.merge!({ 'chatwoot_id' => contact_id })
    contact.custom_attributes.merge!(body['custom_attributes'])
    contact
  end
end
