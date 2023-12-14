class Accounts::Apps::Chatwoots::SyncImportContacts
  def self.call(chatwoot)
    response = create_contact(chatwoot) 
    return {ok: response}
  end

  def self.create_contact(chatwoot)
    quantity_per_page = 15
    quantity_contacts = get_quantity_contacts(chatwoot)
    total_pages = (quantity_contacts / quantity_per_page) + 1
    contacts_imported = 0
    contacts_failed = 0
    contacts_updated = 0
    total_pages.times do |page|
    # ((quantity_contacts / quantity_per_page).ceil).times do |page|
      request = Faraday.get(
        "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/",
        { page: page + 1 },
        chatwoot.request_headers
      )
      if request.status == 200 
        chatwoot_contacts = JSON.parse(request.body)['payload']
        chatwoot_contacts.each do |chatwoot_contact|
          contact = Accounts::Contacts::GetByParams.call(Account.first, chatwoot_contact.slice('email', 'phone').transform_values(&:to_s))
          if contact[:ok]     
            update_contact_chatwoot_id(contact[:ok], chatwoot_contact['id'])
            contacts_updated = contacts_updated + 1
            # response = 'Contact updated successfully'
          else
            contact = build_contact_att(chatwoot_contact, chatwoot)
            if contact.save
              contacts_imported = contacts_imported + 1
              # response = 'Contact created successfully'
            else
              contacts_failed = contacts_failed + 1
              # response = 'Contacts could not be created'
            end
          end
          # response
        end
      else 
        return {error: request.body}
      end
    end
    return "Contacts imported #{contacts_imported} / Contacts updated #{contacts_updated} / Contacts failed #{contacts_failed}"
  end
  def self.update_contact_chatwoot_id(contact, chatwoot_id)
    contact.update(additional_attributes: { chatwoot_id: chatwoot_id })
  end
  def self.get_quantity_contacts(chatwoot)
    request = Faraday.get(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/",
      { page: 1 },
      chatwoot.request_headers
    )    
    if request.status == 200
      quantity = JSON.parse(request.body)['meta']['count']
      return quantity
    else
      return { error: request.body }
    end
  end
  def self.build_contact_att(body, chatwoot)
    contact = chatwoot.account.contacts.new(
      full_name: body['name'],
      email: "#{body['email']}",
      phone: "#{body['phone_number']}"
    )
    contact.additional_attributes.merge!({ 'chatwoot_id' => body['id'] })
    contact.custom_attributes.merge!(body['custom_attributes'])
    contact
  end
end
