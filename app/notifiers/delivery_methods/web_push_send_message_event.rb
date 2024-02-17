class DeliveryMethods::WebPushSendMessageEvent < ApplicationDeliveryMethod
  # Specify the config options your delivery method requires in its config block
  required_options # :foo, :bar

  def deliver
    event = params[:event]
    if event.present?
      recipient.webpush_subscriptions.each do |sub|
        sub.send_notification({
          title: "#{Event.human_attribute_name(event.kind)} sended",
          body: "Mensagem enviada para: #{event.contact.full_name}. Negócio: #{event.deal.name}",
          icon: "#{ENV['FRONTEND_URL']}#{ActionController::Base.helpers.image_url("logo-patinha.svg")}"
        })
      end
    end
    # Logic for sending the notification
  end
end
