class Accounts::Apps::WppConnects::Webhooks::Groups::Onparticipantschanged
  def self.call(wpp_connect, webhook)
    contact = Accounts::Apps::WppConnects::Sync::Group.call(wpp_connect, get_group_id(webhook) )[:ok]
    event = Accounts::Apps::WppConnects::Events::Create::Information.call(wpp_connect, contact, build_message(webhook))
    return { ok: event}
  end

  def self.build_message(webhook)
    "#{get_id(webhook['by'])} #{webhook['operation']} #{webhook['who']}"
  end

  def self.get_id(value)
    value.split('@')[0]
  end

  def self.get_group_id(webhook)
    get_id(webhook['groupId'])
  end
end