class Accounts::Settings::WebhooksController < InternalController
  before_action :set_webhook, only: %i[ edit update destroy ]

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
      redirect_to account_webhooks_path(current_user.account), notice: "Webhook was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @webhook.update(webhook_params)
      redirect_to edit_account_webhook_path(current_user.account, @webhook), notice: "Webhook updated successfully"
    else
      render :edit, status: :unprocessable_entity 
    end
  end
  def destroy
    if @webhook.destroy
      flash[:notice] = "webhook has been deleted"
    else
      render :index, status: :unprocessable_entity 
    end
  end

  private
  def set_webhook
    @webhook = Webhook.find(params[:id])
  end

  def webhook_params
    params.require(:webhook).permit(:url)
  end
end