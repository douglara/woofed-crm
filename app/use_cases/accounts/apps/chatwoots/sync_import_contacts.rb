class Accounts::Apps::Chatwoots::SyncImportContacts
  def self.call(chatwoot)
    response = create_contact(chatwoot)
    { ok: response }
  end
    
  def self.create_contact(chatwoot)
    contacts_imported = 0
    contacts_failed = 0
    contacts_updated = 0
    quantity_per_page = 1
    page = 0
    until quantity_per_page.zero?
      page += 1
      request = Faraday.get(
        "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/",
        { page: page },
        chatwoot.request_headers
      )
      if request.status == 200
        chatwoot_contacts = JSON.parse(request.body)['payload']
        quantity_per_page = chatwoot_contacts.count
        chatwoot_contacts.each do |chatwoot_contact|
          contact = Accounts::Contacts::GetByParams.call(Account.first,
                                                         chatwoot_contact.slice('email',
                                                                                'phone').transform_values(&:to_s))
          if contact[:ok]
            update_contact_chatwoot_id(contact[:ok], chatwoot_contact['id'])
            contacts_updated += 1
          else
            contact = build_contact_att(chatwoot_contact, chatwoot)
            if contact.save
              contacts_imported += 1
            else
              contacts_failed += 1
            end
          end
        end
      else
        return { error: request.body }
      end
    end
    "Contacts imported #{contacts_imported} / Contacts updated #{contacts_updated} / Contacts failed #{contacts_failed}"
  end

  def self.update_contact_chatwoot_id(contact, chatwoot_id)
    contact.update(additional_attributes: { chatwoot_id: chatwoot_id })
  end

  def self.build_contact_att(body, chatwoot)
    contact = chatwoot.account.contacts.new(
      full_name: body['name'],
      email: (body['email']).to_s,
      phone: (body['phone_number']).to_s
    )
    contact.additional_attributes.merge!({ 'chatwoot_id' => body['id'] })
    contact.custom_attributes.merge!(body['custom_attributes'])
    contact
  end
end
