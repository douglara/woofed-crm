class Accounts::WebpushSubscriptionsController < InternalController

  def create
    webpush_subscription = WebpushSubscription.find_by(auth_key: params[:keys][:auth])
    if !webpush_subscription
      webpush_subscription = WebpushSubscription.new(
        account: current_user.account,
        user: current_user,
        endpoint: params[:endpoint],
        auth_key: params[:keys][:auth],
        p256dh_key: params[:keys][:p256dh]
      )
    end
    if webpush_subscription.save
      render json: webpush_subscription
    else
      render json: webpush_subscription.errors.full_messages
    end

  end

end
