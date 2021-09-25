class FlowItems::ActivitiesKinds::WpConnect::Create

  def self.call(whatsapp_params)
    whatsapp = FlowItems::ActivitiesKinds::WpConnect.new(whatsapp_params)
    whatsapp.enabled = true

    if whatsapp.save
      return { ok: whatsapp }
    else
      return { error: whatsapp }
    end
  end
end