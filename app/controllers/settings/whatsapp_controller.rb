class Settings::WhatsappController < InternalController
  before_action :set_whatsapp, only: %i[ edit disable new_connection new_connection_status ]

  def new
    @whatsapp = FlowItems::ActivitiesKinds::WpConnect.new
  end

  def create
    connection = FlowItems::ActivitiesKinds::WpConnect::Create.call(whatsapp_params)

    respond_to do |format|
      if connection.key?(:ok)
        format.html { redirect_to settings_whatsapp_index_path() }
        format.json { render :create, status: :created}
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @whatsapp.errors, status: :unprocessable_entity }
      end
    end
  end

  def index
    @whatsapps = FlowItems::ActivitiesKinds::WpConnect.all
  end

  def edit
  end

  def pair_qr_code
    result = FlowItems::ActivitiesKinds::WpConnect::CreateQrCode.call(whatsapp_params)

    respond_to do |format|
      if result.key?(:ok)
        @whatsapp = result[:ok][:wp_connect]
        @qr_code = result[:ok][:qr_code]
    
        format.html { render :pair_qr_code}
        format.json { render :pair_qr_code, status: :ok }
      else
        format.html { redirect_to settings_whatsapp_index_path(), status: :unprocessable_entity }
        format.json { render json: @activity_kind.errors, status: :unprocessable_entity }
      end
    end
  end

  def new_connection_status
    status = FlowItems::ActivitiesKinds::WpConnect::Connection::Status.call(whatsapp_params)
    is_connected = status.key?(:ok)

    respond_to do |format|
      format.json { render json: {'connceted': is_connected}, status: :ok }
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
      @whatsapp = FlowItems::ActivitiesKinds::WpConnect.find(params['whatsapp_id'])
    end

    def whatsapp_params
      params.require(:flow_items_activities_kinds_wp_connect).permit(:secretkey, :endpoint_url, :session, :token, :name)
    end
end