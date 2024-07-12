class Accounts::Apps::EvolutionApis::Message::Import
  def initialize(evolution_api, webhook, content)
    @evolution_api = evolution_api
    @webhook = webhook
    @content = content
  end

  def call
    result = create_evolution_api_message_event
    { ok: result }
  end

  def create_evolution_api_message_event
    contact = find_or_create_contact
    import_message(contact)
  end

  def find_or_create_contact
    if group_message?
      find_or_create_group_contact
    else
      find_or_create_person_contact
    end
  end

  def find_or_create_person_contact
    phone_number = '+' + @webhook['data']['key']['remoteJid'].gsub(/\D/, '')
    contact = Accounts::Contacts::GetByParams.call(@evolution_api.account, { phone: phone_number })[:ok]
    contact = create_person_contact(phone_number) if contact.blank?
    update_contact_name_if_missing(contact)
    contact
  end

  def update_contact_name_if_missing(contact)
    if @webhook['data']['key']['fromMe'].to_s == 'false' && contact.full_name.blank?
      contact.update(full_name: @webhook['data']['pushName'])
    end
  end

  def find_or_create_group_contact
    group_id = @webhook['data']['key']['remoteJid']
    group_details = group_details(group_id)
    contact_params = {
      full_name: "#{group_details[:group_name]} - Grupo",
      additional_attributes: group_details
    }

    contact = @evolution_api.account.contacts.where('additional_attributes @> ?', { group_id: group_id }.to_json).first
    if contact.present?
      contact.full_name = contact_params[:full_name]
      contact.additional_attributes = contact.additional_attributes.merge(contact_params[:additional_attributes])
    else
      contact = ContactBuilder.new(
        @evolution_api.account.users.first,
        ActionController::Parameters.new(contact_params)
      ).perform
    end

    contact.save!
    contact
  end

  def create_person_contact(phone_number)
    if @webhook['data']['key']['fromMe'].to_s == 'true'
      Contact.create(phone: phone_number,
                     account: @evolution_api.account)
    else
      Contact.create(full_name: @webhook['data']['pushName'], phone: phone_number,
                     account: @evolution_api.account)
    end
  end

  def group_details(group_id)
    request = Faraday.get(
      "#{@evolution_api.endpoint_url}/group/findGroupInfos/#{@evolution_api.instance}?groupJid=#{group_id}",
      {},
      @evolution_api.request_instance_headers
    )
    request_body = JSON.parse(request.body)

    { group_id: group_id,
      group_name: request_body['subject'],
      group_owner_id: request_body['subjectOwner'] }
  end

  def group_message?
    @webhook['data']['key']['remoteJid'].gsub(/\D/, '').size > 15
  end

  def import_message(contact)
    Event.create(
      account: @evolution_api.account,
      kind: 'evolution_api_message',
      from_me: @webhook['data']['key']['fromMe'],
      contact: contact,
      content: @content,
      done: true,
      done_at: @webhook['date_time'],
      app: @evolution_api,
      additional_attributes: { message_id: @webhook['data']['key']['id'] }
    )
  end
end
