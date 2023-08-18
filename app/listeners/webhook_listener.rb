class WebhookListener

  def extract_changed_attributes(event)
    changed_attributes = event.previous_changes
    return nil if changed_attributes.blank?
    changed_attributes.map { |k, v| { k => { previous_value: v[0], current_value: v[1] } } }
  end

  ## Contact
  def contact_updated(contact)
    if (contact.account.webhooks.present?)
      contact.account.webhooks.each do | wh |
        WebhookWorker.perform_async(wh.url, build_contact_payload( 'contact_updated', contact))
      end
    end
  end

  def contact_created(contact)
    if (contact.account.webhooks.present?)
      contact.account.webhooks.each do | wh |
        WebhookWorker.perform_async(wh.url, build_contact_payload( 'contact_created', contact))
      end
    end
  end

  ## Deal

  def deal_updated(deal)
    if (deal.account.webhooks.present?)
      deal.account.webhooks.each do | wh |
        WebhookWorker.perform_async(wh.url, build_payload( 'deal_updated', deal))
      end
    end
  end

  def deal_created(deal)
    if (deal.account.webhooks.present?)
      deal.account.webhooks.each do | wh |
        WebhookWorker.perform_async(wh.url, build_payload( 'deal_created', deal))
      end
    end
  end

  def build_payload(event, deal)
    deal_json = deal.to_json(:include => :contacts)
    { event: event, data: JSON.parse(deal_json)  }.to_json
  end

  def build_contact_payload(event, contact)
    changed_attributes = extract_changed_attributes(contact)

    contact_json = contact.as_json(:include => :deals).merge({changed_attributes: changed_attributes})
    { event: event, data: contact_json }.to_json
  end
end