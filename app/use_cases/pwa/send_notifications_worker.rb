class Pwa::SendNotificationsWorker < ApplicationJob
  self.queue_adapter = :good_job

  def perform(event_id)
    event = Event.find(event_id)
    if event.present? && event.should_delivery_event_scheduled?
      WebpushSubscription.find_each do |subscription|
        if subscription.user.webpush_notify_on_event_expired
          subscription.send_notification(
            {
              title: "#{Event.human_enum_name(:kind, event.kind)} #{event.title}",
              body: I18n.t('use_cases.pwa.send_notifications_worker.body',
                           event_kind: Event.human_enum_name(:kind, event.kind), event_title: event.title, deal_name: event.deal.name),
              icon: ActionController::Base.helpers.image_url('logo-patinha.svg'),
              url: Rails.application.routes.url_helpers.account_deal_url(Current.account, event.deal)
            }
          )
        end
      end
    end
  end
end
