class Accounts::Apps::EvolutionApisController < InternalController
  before_action :set_evolution_api, only: %i[ edit pair_qr_code]

  def new
    @evolution_api = Apps::EvolutionApi.new
  end

  def create
    result = Accounts::Apps::EvolutionApis::Create.call(current_user, evolution_api_params)
    @evolution_api = result[result.keys.first]
    respond_to do |format|
      if result.key?(:ok)
        format.html { redirect_to account_apps_evolution_api_pair_qr_code_path(current_user.account, @evolution_api.id) }
        format.json { render :create, status: :created }
      else
        @evolution_api = result[:error]
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @evolution_api[:error].errors, status: :unprocessable_entity }
      end
    end
  end

  def index
    @evolution_apis = current_user.account.apps_evolution_apis.order(updated_at: :desc)
    @pagy, @evolution_apis = pagy(@evolution_apis)
  end

  def edit
  end

  def pair_qr_code


    # respond_to do |format|
    #   if result.key?(:ok)
    #     @whatsapp = result[:ok][:wp_connect]
    #     @qr_code = result[:ok][:qr_code]

    #     format.html { render :pair_qr_code, status: :ok }
    #     format.json { render :pair_qr_code, status: :ok }
    #   else
    #     puts(result.inspect)
    #     format.html { redirect_to account_apps_wpp_connects_path(current_user.account), status: :unprocessable_entity }
    #   end
    # end
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
    def set_evolution_api
      @evolution_api = Apps::EvolutionApi.find(params['evolution_api_id'])
    end

    def evolution_api_params
      params.require(:apps_evolution_api).permit(:name, :token, :instance, :endpoint_url)
    end
end
