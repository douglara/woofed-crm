class Accounts::Apps::Chatwoots::ExportContact

    def self.call(chatwoot, contact)
      response = create_or_update_contact(chatwoot, contact)
      return response
    end
  
    def self.create_or_update_contact(chatwoot, contact)
      contact_chatwoot_id = contact['additional_attributes']['chatwoot_id']   
      if contact_chatwoot_id.present?
        response = update_contact(chatwoot, contact)
      else
        response = create_contact(chatwoot, contact)
      end
      return response
    end
  
    def self.update_contact(chatwoot, contact)
      request = Faraday.put(
        "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{contact.additional_attributes['chatwoot_id']}",
        build_body(contact),
        chatwoot.request_headers
      )
      if request.status == 200
        return { ok: contact }
      else
        return { error: request.body }
      end
    end


    def self.create_contact(chatwoot, contact)
        request = Faraday.post(
          "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts",
          build_body(contact),
          chatwoot.request_headers
        )  
        response_body = JSON.parse(request.body)   
        if response_body['message'] == 'Email has already been taken' && request.status == 422
          chatwoot_contact = Accounts::Apps::Chatwoots::SearchContact.call(chatwoot, contact['email'])
          update_contact_chatwoot_id(contact, chatwoot_contact['id'])
          return { ok: contact }
        elsif response_body['message'] == 'Phone number has already been taken' && request.status == 422
          chatwoot_contact = Accounts::Apps::Chatwoots::SearchContact.call(chatwoot, contact['phone'])
          update_contact_chatwoot_id(contact, chatwoot_contact['id'])
          return { ok: contact }
        elsif request.status == 200
          update_contact_chatwoot_id(contact, response_body['payload']['contact']['id'])
          return { ok: contact }
        else
          return { error: request.body }
        end
    end
    
    def self.update_contact_chatwoot_id(contact, chatwoot_id)
        contact.update(additional_attributes: { chatwoot_id: chatwoot_id})
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