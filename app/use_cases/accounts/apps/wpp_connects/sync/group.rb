class Accounts::Apps::WppConnects::Sync::Group

  def self.call(wpp_connect, group_id)
    return {ok: import_group(wpp_connect, group_id)}
  end

  def self.import_group(wpp_connect, group_id)

    response = Faraday.get(
      "#{wpp_connect.endpoint_url}/api/#{wpp_connect.session}/all-groups",
      {},
      {'Authorization': "Bearer #{wpp_connect.token}", 'Content-Type': 'application/json'}
    )

    body = JSON.parse(response.body)
    group = body['response'].select { | group | group['id']['user'] == group_id }[0]
  
    contact_find = Contact.find_by('app_id = ? and additional_attributes @> ?', wpp_connect.id, {"wpp_connect_id"=> group['id']['user']}.to_json, )
    if contact_find == nil
      result = Contact.create(
        full_name: "#{group['name']}",
        app: wpp_connect,
        account: wpp_connect.account,
        additional_attributes: {'wpp_connect_id': group['id']['user'] }
      )
      return result
    else
      return contact_find
    end
  end
end