class Accounts::Apps::WppConnects::Sync::Contact

  def self.call(wpp_connect, phone)
    return {ok: import_contact(wpp_connect, phone)}
  end

  def self.import_contact(wpp_connect, phone)
    number_without_9_digit = number_without_9_digit(phone)
    response = Faraday.get(
      "#{wpp_connect.endpoint_url}/api/#{wpp_connect.session}/contact/#{number_without_9_digit}",
      {},
      {'Authorization': "Bearer #{wpp_connect.token}", 'Content-Type': 'application/json'}
    )

    body = JSON.parse(response.body)
    contact_response = body['response']
  
    contact_find = Contact.find_by('app_id = ? and additional_attributes @> ?', wpp_connect.id, {"wpp_connect_id"=> contact_response['id']['user']}.to_json, )
    if contact_find == nil
      result = Contact.create(
        full_name: "#{contact_response['name']}",
        phone: contact_response['id']['user'],
        app: wpp_connect,
        account: wpp_connect.account,
        additional_attributes: {'wpp_connect_id': contact_response['id']['user'] }
      )
      return result
    else
      return contact_find
    end
  end

  def self.number_without_9_digit(number)
    number_without_55 = number[2..-1]
    nubmer_with_9_digit = number_without_55.size == 10 ? "#{number_without_55}".insert(2, '9') : number_without_55
    number_without_9_digit = number_without_55.size == 11 ? number_without_55[0..1] + number_without_55[3..-1] : number_without_55
    return "#{number[0..1]}#{number_without_9_digit}"
  end
end