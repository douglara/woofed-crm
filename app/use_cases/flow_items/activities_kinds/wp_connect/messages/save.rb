class FlowItems::ActivitiesKinds::WpConnect::Messages::Save

  def self.call(message)
    wp_connect = FlowItems::ActivitiesKinds::WpConnect.find_by_session(message['session'])

    contacts = contacts_for_number(extract_phone(message['chatId']))
    contacts.each do | contact |
      save(contact, message, wp_connect)
    end 
    { ok: true}
  end

  def self.extract_phone(chat_id)
    chat_id.split('@')[0]
  end

  def self.save(contact, message, wp_connect)
    item = FlowItem.where(contact_id: contact.id).item_where(source_id: message['id'])
    item_args = { contact_id: contact.id, source_id: message['id'], done: true, wp_connect_id: wp_connect.id,
                  due: Time.at(message['timestamp']), content: message['content'], from_me: message['fromMe'], kind: wp_connect }

    if item.blank?
      FlowItem.create(item_args)
    else
      item.update(item_args)
    end
  end

  def self.contacts_for_number(number)
    number_without_55 = number[2..-1]
    nubmer_with_9_digit = number_without_55.size == 10 ? "#{number_without_55}".insert(2, '9') : number_without_55
    number_without_9_digit = number_without_55.size == 11 ? number_without_55[0..1] + number_without_55[3..-1] : number_without_55

    Contact.where(phone: [number_without_55, nubmer_with_9_digit, number_without_9_digit])
  end
end