class Accounts::Apps::WppConnectsController < InternalController
  before_action :set_whatsapp, only: %i[ edit disable new_connection pair_qr_code new_connection_status ]

  def new
    @wpp_connect = Apps::WppConnect.new
    #@whatsapp = FlowItems::ActivitiesKinds::WpConnect.new
  end

  def create
    @wpp_connect_result = Accounts::Apps::WppConnects::Create.call(current_user.account, wp_connect_params)

    respond_to do |format|
      if @wpp_connect_result.key?(:ok)
        format.html { redirect_to account_apps_wpp_connect_pair_qr_code_path(current_user.account, @wpp_connect_result[:ok].id ) }
        format.json { render :create, status: :created}
      else
        @wpp_connect = @wpp_connect_result[:error]
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @wpp_connect[:error].errors, status: :unprocessable_entity }
      end
    end
  end

  def index
    @wp_connects = current_user.account.apps_wpp_connects.order(updated_at: :desc)
  end

  def edit
  end

  def pair_qr_code
    result = Accounts::Apps::WppConnects::CreateQrCode.call(@wpp_connect.id)

    respond_to do |format|
      if result.key?(:ok)
        @whatsapp = result[:ok][:wp_connect]
        @qr_code = result[:ok][:qr_code]

        format.html { render :pair_qr_code, status: :ok }
        format.json { render :pair_qr_code, status: :ok }
      else
        puts(result.inspect)
        format.html { redirect_to account_apps_wpp_connects_path(current_user.account), status: :unprocessable_entity }
      end
    end
  end

  def new_connection_status
    status = Accounts::Apps::WppConnects::Connection::Status.call(@wpp_connect.id)

    respond_to do |format|
      if status.key?(:ok)
        format.json { render json: {'connceted': true }, status: :ok }
      else
        format.json { render json: {'connceted': false, qr_code: status[:error]['qrcode'] }, status: :ok }
      end
    end
  end

  def disable
    @whatsapp.enabled = false

    respond_to do |format|
      if @whatsapp.save
        format.html { redirect_to settings_whatsapp_index_path()}
        format.json { render :edit, status: :ok, location: @whatsapp }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @whatsapp.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def set_whatsapp
      @wpp_connect = Apps::WppConnect.find(params['wpp_connect_id'])
    end

    def wp_connect_params
      params.require(:apps_wpp_connect).permit(:secretkey, :endpoint_url, :session, :token, :name)
    end
end