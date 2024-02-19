class DeliveryMethods::WebPushAlertEvent < ApplicationDeliveryMethod
  # Specify the config options your delivery method requires in its config block
  required_options # :foo, :bar

  def deliver
    event = params[:event]
    if event.present?
      if !event.done? && event.scheduled_at.present? && (event.scheduled_at - Time.current.in_time_zone).abs <= 5.minutes
        recipient.webpush_subscriptions.each do |sub|
        sub.send_notification({
          title: "#{Event.human_attribute_name(event.kind)} #{event.title}",
          body: "O prazo da a atividade (#{event.title}) do negócio (#{event.deal.name}) irá expirar em breve.",
          icon: "#{ENV['FRONTEND_URL']}#{ActionController::Base.helpers.image_url("logo-patinha.svg")}",
          url: event.get_show_deal_path
        })
      end
      end
    end
    # Logic for sending the notification
  end
end
