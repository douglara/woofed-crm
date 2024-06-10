class Accounts::WebpushSubscriptionsController < InternalController
  def create
    webpush_subscription = WebpushSubscription.new(
      user: current_user,
      endpoint: params[:endpoint],
      auth_key: params[:keys][:auth],
      p256dh_key: params[:keys][:p256dh]
    )
    if webpush_subscription.save
      render json: webpush_subscription
    else
      render json: webpush_subscription.errors.full_messages, status: :unprocessable_entity
    end
  end
end
