class WebhookListener
  def deal_updated(deal)
    if (deal.account.webhooks.present?)
      deal.account.webhooks.each do | wh |
        WebhookWorker.perform_async(wh.url, build_payload( 'updated', deal))
      end
    end
  end

  def deal_created(deal)
    if (deal.account.webhooks.present?)
      deal.account.webhooks.each do | wh |
        WebhookWorker.perform_async(wh.url, build_payload( 'created', deal))
      end
    end
  end

  def build_payload(event, deal)
    deal_json = deal.to_json(:include => :contacts)
    { event: event, data: JSON.parse(deal_json)  }.to_json
  end
end