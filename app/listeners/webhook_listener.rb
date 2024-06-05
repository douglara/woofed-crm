class WebhookListener
  def extract_changed_attributes(event)
    changed_attributes = event.previous_changes
    return nil if changed_attributes.blank?
    changed_attributes.map { |k, v| { k => { previous_value: v[0], current_value: v[1] } } }
  end

  ## Contact
  def contact_updated(contact)
    if (Webhook.all.present?)
      Webhook.all.each do | wh |
        WebhookWorker.perform_async(wh.url, build_contact_payload( 'contact_updated', contact))
      end
    end
  end

  def contact_created(contact)
    if (Webhook.all.present?)
      Webhook.all.each do | wh |
        WebhookWorker.perform_async(wh.url, build_contact_payload( 'contact_created', contact))
      end
    end
  end

  ## Deal

  def deal_updated(deal)
    if (Webhook.all.present?)
      Webhook.all.each do | wh |
        WebhookWorker.perform_async(wh.url, build_deal_payload( 'deal_updated', deal))
      end
    end
  end

  def deal_created(deal)
    if (Webhook.all.present?)
      Webhook.all.each do | wh |
        WebhookWorker.perform_async(wh.url, build_deal_payload( 'deal_created', deal))
      end
    end
  end

  def build_deal_payload(event, deal)
    changed_attributes = extract_changed_attributes(deal)

    deal_json = deal.as_json(:include => :contact).merge({changed_attributes: changed_attributes})
    { event: event, data: deal_json }.to_json
  end

  def build_contact_payload(event, contact)
    changed_attributes = extract_changed_attributes(contact)

    contact_json = contact.as_json(:include => :deals).merge({changed_attributes: changed_attributes})
    { event: event, data: contact_json }.to_json
  end

  ## Events

  def event_created(event)
    if (Webhook.all.present?)
      Webhook.all.each do | wh |
        WebhookWorker.perform_async(wh.url, build_event_payload( 'event_created', event))
      end
    end
  end

  def event_updated(event)
    if (Webhook.all.present?)
      Webhook.all.each do | wh |
        WebhookWorker.perform_async(wh.url, build_event_payload( 'event_updated', event))
      end
    end
  end

  def build_event_payload(event, event_model)
    changed_attributes = extract_changed_attributes(event_model)

    event_json = event_model.as_json(include: %i[deal contact],
                                     methods: :content).merge({ changed_attributes: changed_attributes })
    { event: event, data: event_json }.to_json
  end
end
