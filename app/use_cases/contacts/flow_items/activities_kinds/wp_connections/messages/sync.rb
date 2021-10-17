class Contacts::FlowItems::ActivitiesKinds::WpConnections::Messages::Sync

  def self.call(contact)
    wp_connections = FlowItems::ActivitiesKinds::WpConnect.where(enabled: true)
    wp_connections.each do | wp_connect |
      chat = get_chat(contact.phone, wp_connect)
      sync_chat(chat[:ok], contact, wp_connect) if chat.key?(:ok)
    end
    { ok: true}
  end

  def self.sync_chat(chat, contact, wp_connect)
    chat.each do | m |
      item = FlowItem.where(contact_id: contact.id).item_where(source_id: m['id'])
      item_args = { contact_id: contact.id, source_id: m['id'], done: true, wp_connect_id: wp_connect.id,
                    due: Time.at(m['timestamp']), content: m['content'], from_me: m['fromMe'], kind: wp_connect }

      if item.blank?
        FlowItem.create(item_args)
      else
        item.update(item_args)
      end
    end
  end

  def self.get_chat(phone, wp_connect)
    response = Faraday.get(
      "#{wp_connect.endpoint_url}/api/#{wp_connect.session}/all-messages-in-chat/#{phone}?isGroup=false&includeMe=true&includeNotifications=false",
      {},
      {'Authorization': "Bearer #{wp_connect.token}", 'Content-Type': 'application/json'}
    )

    body = JSON.parse(response.body)
    return {error: 'Not found'}if body['response'].blank?
    return { ok: body['response']}
  end
end