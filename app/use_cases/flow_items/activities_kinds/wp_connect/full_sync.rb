class FlowItems::ActivitiesKinds::WpConnect::FullSync

  def initialize(wp_connect)
    @wp_connect = wp_connect
  end

  def call
    chats = get_all_chats(@wp_connect)
    chats[:ok].each do | chat |
      sync_chat(chat) 
    end
    { ok: true}
  end

  def get_all_chats(wp_connect)
    response = Faraday.get(
      "#{@wp_connect.endpoint_url}/api/#{@wp_connect.session}/all-chats",
      {},
      {'Authorization': "Bearer #{@wp_connect.token}", 'Content-Type': 'application/json'}
    )

    body = JSON.parse(response.body)
    return { ok: body['response']}
  end

  def sync_chat(chat)
    return {error: 'Non user'} if chat['isUser'] != true
    contacts = contacts_for_number(chat['id']['user'])

    return { error: 'Contact not found'} if contacts.blank?
    contacts.each do | contact |
      handle_sync_chat(chat, contact)
    end
  end

  def handle_sync_chat(chat, contact)
    messages = get_messages(chat)
    messages[:ok].each do | m |
      item = FlowItem.where(contact_id: contact.id).item_where(source_id: m['id'])
      item_args = { contact_id: contact.id, source_id: m['id'], done: true, wp_connect_id: @wp_connect.id,
                    due: Time.at(m['timestamp']), content: m['content'], from_me: m['fromMe'], kind: @wp_connect }

      if item.blank?
        FlowItem.create(item_args)
      else
        item.update(item_args)
      end
    end
  end

  def get_messages(chat)
    response = Faraday.get(
      "#{@wp_connect.endpoint_url}/api/#{@wp_connect.session}/all-messages-in-chat/#{chat['id']['user']}?isGroup=false&includeMe=true&includeNotifications=false",
      {},
      {'Authorization': "Bearer #{@wp_connect.token}", 'Content-Type': 'application/json'}
    )

    body = JSON.parse(response.body)
    return { ok: body['response']}
  end

  def contacts_for_number(number)
    number_without_55 = number[2..-1]
    nubmer_with_9_digit = number_without_55.size == 10 ? "#{number_without_55}".insert(2, '9') : number_without_55
    number_without_9_digit = number_without_55.size == 11 ? number_without_55[0..1] + number_without_55[3..-1] : number_without_55

    Contact.where(phone: [number_without_55, nubmer_with_9_digit, number_without_9_digit])
  end
end