class Accounts::Apps::Chatwoots::SyncImportContacts
  def initialize(chatwoot)
    @chatwoot = chatwoot
    @account = @chatwoot.account
  end

  def call
    response = update_or_create_contact
    { ok: response }
  end

  def update_or_create_contact
    contacts_imported = 0
    contacts_failed = 0
    contacts_updated = 0
    quantity_per_page = 1
    page = 0
    until quantity_per_page.zero?
      page += 1
      request = Faraday.get(
        "#{@chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{@chatwoot.chatwoot_account_id}/contacts/",
        { page: page },
        @chatwoot.request_headers
      )
      if request.status == 200
        chatwoot_contacts = JSON.parse(request.body)['payload']
        quantity_per_page = chatwoot_contacts.count
        chatwoot_contacts.each do |chatwoot_contact|
          contact = Accounts::Contacts::GetByParams.call(@account,
                                                         chatwoot_contact.slice('email',
                                                                                'phone', 'identifier').transform_values(&:to_s))
          if contact[:ok]
            update_contact_chatwoot_id(contact[:ok], chatwoot_contact['id'])
            import_labels(contact[:ok])
            contact[:ok].save
            contacts_updated += 1
          else
            contact = build_contact_att(chatwoot_contact)
            import_labels(contact)
            if contact.save
              contacts_imported += 1
            else
              contacts_failed += 1
              Rails.logger.error("Error import contact from chatwoot #{contact.errors.inspect}, chatwoot: #{@chatwoot.inspect}")
            end
          end
        end
      else
        return { error: request.body }
      end
    end
    "Contacts imported #{contacts_imported} / Contacts updated #{contacts_updated} / Contacts failed #{contacts_failed}"
  end

  def update_contact_chatwoot_id(contact, chatwoot_id)
    contact.additional_attributes.merge!({ 'chatwoot_id' => chatwoot_id })
  end

  def import_labels(contact)
    Accounts::Apps::Chatwoots::Webhooks::ImportContact.import_contact_tags(@chatwoot, contact)
    Accounts::Apps::Chatwoots::Webhooks::ImportContact.import_contact_converstions_tags(@chatwoot, contact)
  end

  def build_contact_att(body)
    contact = @account.contacts.new(
      full_name: body['name'],
      email: (body['email']).to_s,
      phone: (body['phone_number']).to_s
    )
    contact.additional_attributes.merge!({ 'chatwoot_id' => body['id'], 'chatwoot_identifier' => body['identifier'] })
    contact.custom_attributes.merge!(body['custom_attributes'])
    contact
  end
end
