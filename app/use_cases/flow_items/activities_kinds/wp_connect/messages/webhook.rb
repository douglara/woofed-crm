class FlowItems::ActivitiesKinds::WpConnect::Messages::Webhook

  def self.call(event)
    event_hash = eval(event.to_s).stringify_keys

    return {error: 'Is group'} if event_hash['isGroupMsg'] == true
    FlowItems::ActivitiesKinds::WpConnect::Messages::Save.call(event_hash)
    { ok: true}
  end
end