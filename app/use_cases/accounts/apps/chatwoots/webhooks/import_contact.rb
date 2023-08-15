class Accounts::Apps::Chatwoots::Webhooks::ImportContact

  def self.call(chatwoot, contact_id)
    contact = get_or_import_contact(chatwoot, contact_id)
    return { ok: contact }
  end

  def self.get_or_import_contact(chatwoot, contact_id)
    contact = chatwoot.account.contacts.where(
      "? <@ additional_attributes", { chatwoot_id: contact_id }.to_json
    ).first

    if contact.present?
      contact = update_contact(chatwoot, contact_id, contact)
      contact = import_contact_tags(chatwoot, contact)
      contact = import_contact_converstions_tags(chatwoot, contact)
      contact.save
      return contact
    else
      contact = import_contact(chatwoot, contact_id)
      contact = import_contact_tags(chatwoot, contact)
      contact = import_contact_converstions_tags(chatwoot, contact)
      contact.save
      return contact
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
    contact.assign_attributes({chatwoot_contact_label_list: body['payload']})
    return contact
  end

  def self.import_contact(chatwoot, contact_id)
    contact_response = Faraday.get(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{contact_id}",
      {},
      chatwoot.request_headers
    )

    body = JSON.parse(contact_response.body)
    chatwoot.account.contacts.new(
      full_name: body['payload']['name'],
      additional_attributes: { chatwoot_id: contact_id }
    )
  end


  def self.update_contact(chatwoot, contact_id, contact)
    contact_response = Faraday.get(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{contact_id}",
      {},
      chatwoot.request_headers
    )

    body = JSON.parse(contact_response.body)
    contact.assign_attributes({
      full_name: body['payload']['name']
    })
    contact
  end
end