class Accounts::Settings::WebhooksController < InternalController
  before_action :set_webhook, only: %i[edit update destroy]

  def index
    @webhooks = current_user.account.webhooks
    @pagy, @webhooks = pagy(@webhooks)
  end

  def new
    @webhook = Webhook.new
  end

  def create
    @webhook = current_user.account.webhooks.new(webhook_params)
    if @webhook.save
      redirect_to account_webhooks_path(current_user.account),
                  notice: t('flash_messages.created', model: Webhook.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @webhook.update(webhook_params)
      redirect_to edit_account_webhook_path(current_user.account, @webhook),
                  notice: t('flash_messages.updated', model: Webhook.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @webhook.destroy
      flash[:notice] = t('flash_messages.deleted', model: Webhook.model_name.human)
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_webhook
    @webhook = current_user.account.webhooks.find(params[:id])
  end

  def webhook_params
    params.require(:webhook).permit(:url, :status)
  end
end
